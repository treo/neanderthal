(ns uncomplicate.neanderthal.clblast-test
  (:require [midje.sweet :refer :all]
            [uncomplicate.clojurecl.core
             :refer [with-default *command-queue*]]
            [uncomplicate.neanderthal
             [opencl :refer [with-engine *opencl-factory*]]
             [block-test :as block-test]
             [real-test :as real-test]
             [opencl-test :as opencl-test]]
            [uncomplicate.neanderthal.internal.opencl.clblast :refer [clblast-float clblast-double]]))

(with-default
  (with-engine clblast-float *command-queue*
    (block-test/test-all *opencl-factory*)
    (real-test/test-blas *opencl-factory*)
    (opencl-test/test-all *opencl-factory*))
  (with-engine clblast-double *command-queue*
    (block-test/test-all *opencl-factory*)
    (real-test/test-blas *opencl-factory*)
    (opencl-test/test-all *opencl-factory*)))
