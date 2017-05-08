;;   Copyright (c) Dragan Djuric. All rights reserved.
;;   The use and distribution terms for this software are covered by the
;;   Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php) or later
;;   which can be found in the file LICENSE at the root of this distribution.
;;   By using this software in any fashion, you are agreeing to be bound by
;;   the terms of this license.
;;   You must not remove this notice, or any other, from this software.

(ns ^{:author "Dragan Djuric"}
    uncomplicate.neanderthal.internal.cuda.cublas
  (:require [clojure.java.io :as io]
            [uncomplicate.commons
             [core :refer [Releaseable release let-release with-release wrap-int wrap-double wrap-float]]
             [utils :refer [with-check]]]
            [uncomplicate.clojurecuda
             [protocols :refer [cu-ptr ptr]]
             [core :refer :all]
             [toolbox :refer [launch-reduce! count-blocks]]
             [nvrtc :refer [program compile!]]
             [utils :refer [error]]]
            [uncomplicate.neanderthal.native :refer [native-float native-double]]
            [uncomplicate.neanderthal.internal.api :refer :all]
           [uncomplicate.neanderthal.internal.cuda.cublock :refer :all])
  (:import jcuda.runtime.JCuda
           [jcuda.jcublas JCublas2 cublasHandle cublasOperation]
           [uncomplicate.neanderthal.internal.api Vector Matrix Block DataAccessor StripeNavigator
            RealBufferAccessor]
           [uncomplicate.neanderthal.internal.cuda.cublock CUBlockVector CUGEMatrix]))

;; =============== Common vector macros and functions =======================

(defn ^:private vector-equals [modl ^CUBlockVector x ^CUBlockVector y]
  (let [cnt (.dim x)]
    (if (< 0 cnt)
      (with-release [equals-kernel (function modl "vector_equals")
                     eq-flag-buf (mem-alloc Integer/BYTES)]
        (memset! eq-flag-buf 0)
        (launch! equals-kernel (grid-1d cnt)
                 (parameters cnt eq-flag-buf (.buffer x) (.offset x) (.stride x)
                             (.buffer y) (.offset y) (.stride y)))
        (= 0 (aget ^longs (memcpy-host! eq-flag-buf (long-array 1)) 0)))
      (= 0 (.dim y)))))

(defn ^:private vector-subcopy [modl ^CUBlockVector x ^CUBlockVector y kx lx ky]
  (with-release [copy-kernel (function modl "vector_copy")]
    (launch! copy-kernel (grid-1d lx)
             (parameters lx (.buffer x) (+ (.offset x) (* (long kx) (.stride x))) (.stride x)
                         (.buffer y) (+ (.offset y) (* (long ky) (.stride y))) (.stride y)))))

(defn ^:private vector-sum [modl ^CUBlockVector x]
  (let [cnt (.dim x)
        block-dim 1024
        hstream nil];;TODO change later
    (if (< 0 cnt)
      (with-release [sum-kernel (function modl "vector_sum")
                     sum-reduction-kernel (function modl "sum_reduction")
                     cu-acc (mem-alloc (* Double/BYTES (count-blocks block-dim cnt)))]
        (launch-reduce! hstream sum-kernel sum-reduction-kernel
                        [(.buffer x) (.offset x) (.stride x) cu-acc] [cu-acc] cnt block-dim)
        (get ^doubles (memcpy-host! cu-acc (double-array 1)) 0))
      0.0)))

(defn ^:private vector-set [modl alpha ^CUBlockVector x]
  (with-release [set-kernel (function modl "vector_set")]
    (launch! set-kernel (grid-1d (.dim x))
             (parameters (.dim x) alpha (.buffer x) (.offset x) (.stride x)))))

(defn ^:private vector-axpby [modl alpha ^CUBlockVector x beta ^CUBlockVector y]
  (with-release [axpby-kernel (function modl "vector_axpby")]
    (launch! axpby-kernel (grid-1d (.dim x))
             (parameters (.dim x)
                         alpha (.buffer x) (.offset x) (.stride x)
                         beta (.buffer y) (.offset y) (.stride y)))))

(defmacro ^:private vector-method
  ([cublas-handle method x]
   `(when (< 0 (.dim ~x))
      (with-check cublas-error
        (~method ~cublas-handle (.dim ~x)
         (offset (data-accessor ~x) (cu-ptr (.buffer ~x)) (.offset ~x)) (.stride ~x))
        nil)))
  ([cublas-handle method x y]
   `(when (< 0 (.dim ~x))
      (let [da# (data-accessor ~x)]
        (with-check cublas-error
          (~method ~cublas-handle (.dim ~x)
           (offset da# (cu-ptr (.buffer ~x)) (.offset ~x)) (.stride ~x)
           (offset da# (cu-ptr (.buffer ~y)) (.offset ~y)) (.stride ~y))
          nil))))
  ([cublas-handle method x y z]
   `(when (< 0 (.dim x))
      (let [da# (data-accessor ~x)]
        (with-check cublas-error
          (~method ~cublas-handle (.dim ~x)
           (offset da# (cu-ptr (.buffer ~x)) (.offset ~x)) (.stride ~x)
           (offset da# (cu-ptr (.buffer ~y)) (.offset ~y)) (.stride ~y)
           (offset da# (cu-ptr (.buffer ~z)) (.offset ~z)) (.stride ~z)))
          nil))))

(defmacro ^:private vector-dot [cublas-handle array-fn method x y]
  `(if (< 0 (.dim ~x))
     (let [da# (data-accessor ~x)
           res# (~array-fn 1)]
       (with-check cublas-error
         (~method ~cublas-handle (.dim ~x)
          (offset da# (cu-ptr (.buffer ~x)) (.offset ~x)) (.stride ~x)
          (offset da# (cu-ptr (.buffer ~y)) (.offset ~y)) (.stride ~y)
          (ptr res#))
         (first res#)))
     0.0))

(defmacro ^:private vector-reducer [cublas-handle array-fn method x]
  `(if (< 0 (.dim ~x))
     (let [res# (~array-fn 1)]
       (with-check cublas-error
         (~method ~cublas-handle (.dim ~x)
          (offset (data-accessor ~x) (cu-ptr (.buffer ~x)) (.offset ~x)) (.stride ~x) (ptr res#))
         (first res#)))
     0.0))

(defmacro ^:private vector-scal [cublas-handle method alpha x]
  `(when (< 0 (.dim ~x))
     (with-check cublas-error
       (~method ~cublas-handle (.dim ~x) (ptr ~alpha)
        (offset (data-accessor ~x) (cu-ptr (.buffer ~x)) (.offset ~x)) (.stride ~x))
       nil)))

(defmacro ^:private vector-axpy [cublas-handle method alpha x y]
  `(when (< 0 (.dim ~x))
     (let [da# (data-accessor ~x)]
       (with-check cublas-error
         (~method ~cublas-handle (.dim ~x) (ptr ~alpha)
          (offset da# (cu-ptr (.buffer ~x)) (.offset ~x)) (.stride ~x)
          (offset da# (cu-ptr (.buffer ~y)) (.offset ~y)) (.stride ~y))
         nil))))

(defmacro ^:private vector-rot [cublas-handle method x y c s]
  `(let [da# (data-accessor ~x)]
     (with-check cublas-error
       (~method ~cublas-handle (.dim ~x)
        (offset da# (cu-ptr (.buffer ~x)) (.offset ~x)) (.stride ~x)
        (offset da# (cu-ptr (.buffer ~y)) (.offset ~y)) (.stride ~y)
        (ptr ~c) (ptr ~s))
       nil)))

(defmacro ^:private vector-rotm [cublas-handle method x y param]
  `(if (= 1 (.stride ~param))
     (let [da# (data-accessor ~x)]
       (with-check cublas-error
         (~method ~cublas-handle (.dim ~x)
          (offset da# (cu-ptr (.buffer ~x)) (.offset ~x)) (.stride ~x)
          (offset da# (cu-ptr (.buffer ~y)) (.offset ~y)) (.stride ~y)
          (ptr (.buffer ~param)))
         nil))
     (throw (ex-info "You cannot use strided vector as param." {:param (str ~param)}))))

;; =============== Common GE matrix macros and functions =======================

(defn ^:private ge-equals [modl ^CUGEMatrix a ^CUGEMatrix b]
  (if (< 0 (.count a))
    (with-release [equals-kernel (function modl (if (= (.order a) (.order b))
                                                  "ge_equals_no_transp"
                                                  "ge_equals_transp"))
                   eq-flag-buf (mem-alloc Integer/BYTES)]
      (memset! eq-flag-buf 0)
      (launch! equals-kernel (grid-2d (.sd a) (.fd a))
               (parameters (.sd a) (.fd a) eq-flag-buf (.buffer a) (.offset a) (.ld a)
                           (.buffer b) (.offset b) (.ld b)))
      (= 0 (aget ^longs (memcpy-host! eq-flag-buf (long-array 1)) 0)))
    (= 0 (.mrows b) (.ncols b))))

(defn ^:private ge-set [modl alpha ^CUGEMatrix a]
  (if (< 0 (.count a))
    (let [da (data-accessor a)]
      (with-release [ge-set-kernel (function modl "ge_set")]
        (launch! ge-set-kernel (grid-2d (.sd a) (.fd a))
                 (parameters (.sd a) (.fd a) alpha (.buffer a) (.offset a) (.ld a)))))))

(defmacro ^:private ge-swap [cublas-handle method a b]
  `(when (< 0 (.count ~a))
     (let [da# (data-accessor ~a)
           ld-a# (.stride ~a)
           sd-a# (.sd ~a)
           offset-a# (.offset ~a)
           buff-a# (cu-ptr (.buffer ~a))
           ld-b# (.stride ~b)
           fd-b# (.fd ~b)
           offset-b# (.offset ~b)
           buff-b# (cu-ptr (.buffer ~b))]
       (if (= (.order ~a) (.order ~b))
         (if (= sd-a# (.sd ~b) ld-a# ld-b#)
           (with-check cublas-error
             (~method ~cublas-handle (.count ~a) buff-a# 1 (cu-ptr buff-b#) 1)
             nil)
           (dotimes [j# (.fd ~a)]
             (with-check cublas-error
               (~method ~cublas-handle sd-a#
                (offset da# buff-a# (+ offset-a# (* ld-a# j#))) 1
                (offset da# buff-b# (+ offset-b# (* ld-b# j#))) 1)
               nil)))
         (dotimes [j# (.fd ~a)]
           (with-check cublas-error
             (~method ~cublas-handle sd-a#
              (offset da# buff-a# (+ offset-a# (* ld-a# j#))) 1
              (offset da# buff-b# (+ offset-b# j#)) ld-b#)
             nil))))))

(defmacro ^:private ge-scal [cublas-handle method alpha a]
  `(when (< 0 (.count ~a))
     (let [da# (data-accessor ~a)
           a# (offset da# (cu-ptr (.buffer ~a)) (.offset ~a))
           ld-a# (.ld ~a)]
       (with-check cublas-error
         (~method ~cublas-handle cublasOperation/CUBLAS_OP_N cublasOperation/CUBLAS_OP_N
          (.mrows ~a) (.ncols ~a) (ptr ~alpha) a# ld-a# (ptr 0.0) a# ld-a# a# ld-a#)
         nil))))

(defmacro ^:private ge-axpby [cublas-handle method alpha a beta b]
  `(when (< 0 (.count ~a))
     (let [da# (data-accessor ~a)
           b# (offset da# (cu-ptr (.buffer ~b)) (.offset ~b))]
       (with-check cublas-error
         (~method ~cublas-handle
          (if (= (.order ~a) (.order ~b)) cublasOperation/CUBLAS_OP_N cublasOperation/CUBLAS_OP_T)
          cublasOperation/CUBLAS_OP_N (.mrows ~b) (.ncols ~b)
          (ptr ~alpha) (offset da# (cu-ptr (.buffer ~a)) (.offset ~a)) (.ld ~a)
          (ptr ~beta) b# (.ld ~b) b# (.ld ~b))
         nil))))

(defmacro ^:private ge-mv
  ([cublas-handle method alpha a x beta y]
   `(when (< 0 (.count ~a))
      (let [da# (data-accessor ~a)]
        (with-check cublas-error
          (~method ~cublas-handle
           (if (= COLUMN_MAJOR (.order ~a)) cublasOperation/CUBLAS_OP_N cublasOperation/CUBLAS_OP_T)
           (.mrows ~a) (.ncols ~a)
           (ptr ~alpha) (offset da# (cu-ptr (.buffer ~a)) (.offset ~a)) (.stride ~a)
           (offset da# (cu-ptr (.buffer ~x)) (.offset ~x)) (.stride ~x)
           (ptr ~beta) (offset da# (cu-ptr (.buffer ~y)) (.offset ~y)) (.stride ~y))
          nil))))
  ([a]
   `(throw (ex-info "In-place mv! is not supported for GE matrices." {:a (str ~a)}))))

(defmacro ^:private ge-rk [cublas-handle method alpha x y a]
  `(when (< 0 (.count ~a))
     (if (= COLUMN_MAJOR (.order ~a))
       (let [da# (data-accessor ~a)]
         (with-check cublas-error
           (~method ~cublas-handle (.mrows ~a) (.ncols ~a)
            (ptr ~alpha) (offset da# (cu-ptr (.buffer ~x)) (.offset ~x)) (.stride ~x)
            (offset da# (cu-ptr (.buffer ~y)) (.offset ~y)) (.stride ~y)
            (offset da# (cu-ptr (.buffer ~a)) (.offset ~a)) (.ld ~a))
           nil))
       (throw (ex-info "cuBLAS engine doesn't support rank-1 on non-column oriented GE matrices.")))))

(defmacro ^:private ge-mm
  ([alpha a b left]
   `(if ~left
      (mm (engine ~b) ~alpha ~b ~a false)
      (throw (ex-info "In-place mm! is not supported for GE matrices." {:a (str ~a)}))))
  ([cublas-handle method alpha a b beta c]
   `(when (< 0 (.count ~a))
      (let [da# (data-accessor ~a)]
        (if (= COLUMN_MAJOR (.order ~a))
          (with-check cublas-error
            (~method ~cublas-handle
             (if (= (.order ~a) (.order ~c)) cublasOperation/CUBLAS_OP_N cublasOperation/CUBLAS_OP_T)
             (if (= (.order ~b) (.order ~c)) cublasOperation/CUBLAS_OP_N cublasOperation/CUBLAS_OP_T)
             (.mrows ~a) (.ncols ~b) (.ncols ~a)
             (ptr ~alpha) (offset da# (cu-ptr (.buffer ~a)) (.offset ~a)) (.stride ~a)
             (offset da# (cu-ptr (.buffer ~b)) (.offset ~b)) (.stride ~b)
             (ptr ~beta) (offset da# (cu-ptr (.buffer ~c)) (.offset ~c)) (.stride ~c))
            nil)
          (throw (ex-info "cuBLAS engine doesn't support multiplication of non-column oriented GE matrices.")))))))

(deftype DoubleVectorEngine [cublas-handle modl]
  BlockEngine
  (equals-block [_ x y]
    (vector-equals modl ^CUBlockVector x ^CUBlockVector y))
  Blas
  (swap [_ x y]
    (vector-method cublas-handle JCublas2/cublasDswap ^CUBlockVector x ^CUBlockVector y)
    x)
  (copy [_ x y]
    (vector-method cublas-handle JCublas2/cublasDcopy ^CUBlockVector x ^CUBlockVector y)
    y)
  (dot [_ x y]
    (vector-dot cublas-handle double-array JCublas2/cublasDdot ^CUBlockVector x ^CUBlockVector y))
  (nrm2 [_ x]
    (vector-reducer cublas-handle double-array JCublas2/cublasDnrm2 ^CUBlockVector x))
  (asum [_ x]
    (vector-reducer cublas-handle double-array JCublas2/cublasDasum ^CUBlockVector x))
  (iamax [_ x]
    (max 0 (dec (long (vector-reducer cublas-handle int-array JCublas2/cublasIdamax ^CUBlockVector x)))))
  (iamin [_ x]
    (max 0 (dec (long (vector-reducer cublas-handle int-array JCublas2/cublasIdamin ^CUBlockVector x)))))
  (rot [_ x y c s]
    (vector-rot cublas-handle JCublas2/cublasDrot ^CUBlockVector x ^CUBlockVector y (double c) (double s))
    x)
  (rotg [_ _]
    (throw (UnsupportedOperationException. "Not available in CUDA. Please use a host instance.")))
  (rotm [_ x y param]
    (vector-rotm cublas-handle JCublas2/cublasDrotm  ^CUBlockVector x ^CUBlockVector y ^CUBlockVector param)
    x)
  (rotmg [_ _ _]
    (throw (UnsupportedOperationException. "Not available in CUDA. Please use a host instance.")))
  (scal [_ alpha x]
    (vector-scal cublas-handle JCublas2/cublasDscal (double alpha) ^CUBlockVector x)
    x)
  (axpy [_ alpha x y]
    (vector-axpy cublas-handle JCublas2/cublasDaxpy (double alpha) ^CUBlockVector x ^CUBlockVector y)
    y)
  BlasPlus
  (subcopy [_ x y kx lx ky]
    (vector-subcopy modl ^CUBlockVector x ^CUBlockVector y kx lx ky)
    y)
  (sum [_ x]
    (vector-sum modl ^CUBlockVector x))
  (imax [_ x]
    (throw (UnsupportedOperationException. "TODO.")))
  (imin [this x]
    (throw (UnsupportedOperationException. "TODO.")))
  (set-all [_ alpha x]
    (vector-set modl (double alpha) ^CUBlockVector x)
    x)
  (axpby [_ alpha x beta y]
    (vector-axpby modl (double alpha) x (double beta) y)
    y))

(deftype FloatVectorEngine [cublas-handle modl]
  BlockEngine
  (equals-block [_ x y]
    (vector-equals modl ^CUBlockVector x ^CUBlockVector y))
  Blas
  (swap [_ x y]
    (vector-method cublas-handle JCublas2/cublasSswap ^CUBlockVector x ^CUBlockVector y)
    x)
  (copy [_ x y]
    (vector-method cublas-handle JCublas2/cublasScopy ^CUBlockVector x ^CUBlockVector y)
    y)
  (dot [_ x y]
    (vector-dot cublas-handle float-array JCublas2/cublasSdot ^CUBlockVector x ^CUBlockVector y))
  (nrm2 [_ x]
    (vector-reducer cublas-handle float-array JCublas2/cublasSnrm2 ^CUBlockVector x))
  (asum [_ x]
    (vector-reducer cublas-handle float-array JCublas2/cublasSasum ^CUBlockVector x))
  (iamax [_ x]
    (max 0 (dec (long (vector-reducer cublas-handle int-array JCublas2/cublasIsamax ^CUBlockVector x)))))
  (iamin [_ x]
    (max 0 (dec (long (vector-reducer cublas-handle int-array JCublas2/cublasIsamin ^CUBlockVector x)))))
  (rot [_ x y c s]
    (vector-rot cublas-handle JCublas2/cublasSrot ^CUBlockVector x ^CUBlockVector y (float c) (float s))
    x)
  (rotg [_ _]
    (throw (UnsupportedOperationException. "Not available in CUDA. Please use a host instance.")))
  (rotm [_ x y param]
    (vector-rotm cublas-handle JCublas2/cublasSrotm  ^CUBlockVector x ^CUBlockVector y ^CUBlockVector param)
    x)
  (rotmg [_ _ _]
    (throw (UnsupportedOperationException. "Not available in CUDA. Please use a host instance.")))
  (scal [_ alpha x]
    (vector-scal cublas-handle JCublas2/cublasSscal (float alpha) ^CUBlockVector x)
    x)
  (axpy [_ alpha x y]
    (vector-axpy cublas-handle JCublas2/cublasSaxpy (float alpha) ^CUBlockVector x ^CUBlockVector y)
    y)
  BlasPlus
  (subcopy [_ x y kx lx ky]
    (vector-subcopy modl ^CUBlockVector x ^CUBlockVector y kx lx ky)
    y)
  (sum [_ x]
    (vector-sum modl ^CUBlockVector x))
  (imax [_ x]
    (throw (UnsupportedOperationException. "TODO.")))
  (imin [this x]
    (throw (UnsupportedOperationException. "TODO.")))
  (set-all [_ alpha x]
    (vector-set modl (float alpha) ^CUBlockVector x)
    x)
  (axpby [_ alpha x beta y]
    (vector-axpby modl (float alpha) x (float beta) y)
    y))

(deftype DoubleGEEngine [cublas-handle modl]
  BlockEngine
  (equals-block [_ a b]
    (ge-equals modl a b))
  Blas
  (swap [_ a b]
    (ge-swap cublas-handle JCublas2/cublasDswap ^CUGEMatrix a ^CUGEMatrix b)
    a)
  (copy [_ a b]
    (ge-axpby cublas-handle JCublas2/cublasDgeam (double 1) ^CUGEMatrix a (double 0) ^CUGEMatrix b)
    b)
  (scal [_ alpha a]
    (ge-scal cublas-handle JCublas2/cublasDgeam (double alpha) ^CUGEMatrix a)
    a)
  (axpy [_ alpha a b]
    (ge-axpby cublas-handle JCublas2/cublasDgeam (double alpha) ^CUGEMatrix a (double 1.0) ^CUGEMatrix b)
    b)
  (mv [_ alpha a x beta y]
    (ge-mv cublas-handle JCublas2/cublasDgemv
           (double alpha) ^CUGEMatrix a ^CUBlockVector x (beta beta) ^CUBlockVector y)
    y)
  (mv [this a x]
    (ge-mv a))
  (rk [_ alpha x y a]
    (ge-rk cublas-handle JCublas2/cublasDger (double alpha) ^CUBlockVector x ^CUBlockVector y ^CUGEMatrix a)
    a)
  (mm [_ alpha a b left]
    (ge-mm alpha a b left))
  (mm [_ alpha a b beta c]
    (ge-mm cublas-handle JCublas2/cublasDgemm
           (double alpha) ^CUGEMatrix a ^CUGEMatrix b (double beta) ^CUGEMatrix c)
    c)
  BlasPlus
  (set-all [_ alpha a]
    (ge-set modl (double alpha) a)
    a)
  (axpby [_ alpha a beta b]
    (ge-axpby cublas-handle JCublas2/cublasDgeam (double alpha) ^CUGEMatrix a (double beta) ^CUGEMatrix b)
    b))

(deftype FloatGEEngine [cublas-handle modl]
  BlockEngine
  (equals-block [_ a b]
    (ge-equals modl a b))
  Blas
  (swap [_ a b]
    (ge-swap cublas-handle JCublas2/cublasSswap ^CUGEMatrix a ^CUGEMatrix b)
    a)
  (copy [_ a b]
    (ge-axpby cublas-handle JCublas2/cublasSgeam (float 1) ^CUGEMatrix a (float 0) ^CUGEMatrix b)
    b)
  (scal [_ alpha a]
    (ge-scal cublas-handle JCublas2/cublasSgeam (float alpha) ^CUGEMatrix a)
    a)
  (axpy [_ alpha a b]
    (ge-axpby cublas-handle JCublas2/cublasSgeam (float alpha) ^CUGEMatrix a (float 1.0) ^CUGEMatrix b)
    b)
  (mv [_ alpha a x beta y]
    (ge-mv cublas-handle JCublas2/cublasSgemv
           (float alpha) ^CUGEMatrix a ^CUBlockVector x (beta beta) ^CUBlockVector y)
    y)
  (mv [this a x]
    (ge-mv a))
  (rk [_ alpha x y a]
    (ge-rk cublas-handle JCublas2/cublasSger (float alpha) ^CUBlockVector x ^CUBlockVector y ^CUGEMatrix a)
    a)
  (mm [_ alpha a b left]
    (ge-mm alpha a b left))
  (mm [_ alpha a b beta c]
    (ge-mm cublas-handle JCublas2/cublasSgemm
           (float alpha) ^CUGEMatrix a ^CUGEMatrix b (float beta) ^CUGEMatrix c)
    c)
  BlasPlus
  (set-all [_ alpha a]
    (ge-set modl (float alpha) a)
    a)
  (axpby [_ alpha a beta b]
    (ge-axpby cublas-handle JCublas2/cublasSgeam (float alpha) ^CUGEMatrix a (float beta) ^CUGEMatrix b)
    b))

(deftype CUFactory [modl ^DataAccessor da native-fact vector-eng ge-eng tr-eng]
  Releaseable
  (release [_]
    (release vector-eng)
    (release ge-eng)
    (release modl)
    true)
  DataAccessorProvider
  (data-accessor [_]
    da)
  FactoryProvider
  (factory [this]
    this)
  (native-factory [this]
    native-fact)
  MemoryContext
  (compatible? [_ o]
    (compatible? da o))
  Factory
  (create-vector [this n init]
    (let-release [res (cu-block-vector this n)]
      (when init
        (.initialize da (.buffer ^Block res)))
      res))
  (create-ge [this m n ord init]
    (let-release [res (cu-ge-matrix this m n ord)]
      (when init
        (.initialize da (.buffer ^Block res)))
      res))
  (create-tr [this n ord uplo diag init]
    (let-release [res (cu-tr-matrix this n ord uplo diag)]
      (when init
        (.initialize da (.buffer ^Block res)))
      res))
  (vector-engine [_]
    vector-eng)
  (ge-engine [_]
    ge-eng)
  (tr-engine [_]
    tr-eng))

(let [src (str (slurp (io/resource "uncomplicate/clojurecuda/kernels/reduction.cu"))
               (slurp (io/resource "uncomplicate/neanderthal/cuda/kernels/blas-plus.cu")))]

  (JCublas2/setExceptionsEnabled false)

  (defn cublas-double [handle]
    (with-release [prog (compile! (program src) ["-DREAL=double" "-DACCUMULATOR=double" "-arch=compute_30"])]
      (let-release [modl (module prog)]
        (->CUFactory modl (->TypedCUAccessor (current-context) Double/TYPE Double/BYTES wrap-double) native-double
                     (->DoubleVectorEngine handle modl) (->DoubleGEEngine handle modl)
                     nil #_(->DoubleTREngine cublas-handle)))))

  (defn cublas-float [handle]
    (with-release [prog (compile! (program src) ["-DREAL=float" "-DACCUMULATOR=double""-arch=compute_30"])]
      (let-release [modl (module prog)]
        (->CUFactory modl (->TypedCUAccessor (current-context) Float/TYPE Float/BYTES wrap-float) native-float
                     (->FloatVectorEngine handle modl) (->FloatGEEngine handle modl)
                     nil #_(->FloatTREngine cublas-handle))))))

(extend-type cublasHandle
  Releaseable
  (release [this]
    (with-check cublas-error (JCublas2/cublasDestroy this) true)))

(defn cublas-handle
  "TODO"
  ([]
   (let [handle (cublasHandle.)]
     (with-check cublas-error (JCublas2/cublasCreate handle) handle)))
  ([^long device-id]
   (with-check error (JCuda/cudaSetDevice device-id) (cublas-handle))))