#ifndef REAL
#define REAL float
#endif

#ifndef REAL2o3
#define REAL2o3 (REAL)(2.0/3.0)
#endif

#ifndef REAL3o2
#define REAL3o2 (REAL)(3.0/2.0)
#endif

__kernel void vector_sqr (__global const REAL* x, const uint offset_x, const uint stride_x,
                          __global REAL* y, const uint offset_y, const uint stride_y) {
    const REAL xval = x[offset_x + get_global_id(0) * stride_x];
    y[offset_y + get_global_id(0) * stride_y] = xval * xval;
}

__kernel void vector_mul (__global const REAL* x, const uint offset_x, const uint stride_x,
                          __global const REAL* y, const uint offset_y, const uint stride_y,
                          __global REAL* z, const uint offset_z, const uint stride_z) {
    z[offset_z + get_global_id(0) * stride_z] =
        x[offset_x + get_global_id(0) * stride_x] * y[offset_y + get_global_id(0) * stride_y];
}

__kernel void vector_div (__global const REAL* x, const uint offset_x, const uint stride_x,
                          __global const REAL* y, const uint offset_y, const uint stride_y,
                          __global REAL* z, const uint offset_z, const uint stride_z) {
    z[offset_z + get_global_id(0) * stride_z] =
      x[offset_x + get_global_id(0) * stride_x] / y[offset_y + get_global_id(0) * stride_y];
}

__kernel void vector_inv (__global const REAL* x, const uint offset_x, const uint stride_x,
                          __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = (REAL)1.0 / x[offset_x + get_global_id(0) * stride_x];
}

__kernel void vector_abs (__global const REAL* x, const uint offset_x, const uint stride_x,
                          __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = fabs(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_linear_frac (__global const REAL* x, const uint offset_x, const uint stride_x,
                                  __global const REAL* y, const uint offset_y, const uint stride_y,
                                  const REAL scalea, const REAL shifta, const REAL scaleb, const REAL shiftb,
                                  __global REAL* z, const uint offset_z, const uint stride_z) {
    z[offset_z + get_global_id(0) * stride_z] =
        (scalea * x[offset_x + get_global_id(0) * stride_x] + shifta) /
        (scaleb * y[offset_y + get_global_id(0) * stride_y] + shiftb);
}

__kernel void vector_scale_shift (__global const REAL* x, const uint offset_x, const uint stride_x,
                                  const REAL scalea,const REAL shifta,
                                  __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = scalea * x[offset_x + get_global_id(0) * stride_x] + shifta;
}

__kernel void vector_fmod (__global const REAL* x, const uint offset_x, const uint stride_x,
                           __global const REAL* y, const uint offset_y, const uint stride_y,
                           __global REAL* z, const uint offset_z, const uint stride_z) {
    z[offset_z + get_global_id(0) * stride_z] =
        fmod(x[offset_x + get_global_id(0) * stride_x], y[offset_y + get_global_id(0) * stride_y]);
}

__kernel void vector_frem (__global const REAL* x, const uint offset_x, const uint stride_x,
                           __global const REAL* y, const uint offset_y, const uint stride_y,
                           __global REAL* z, const uint offset_z, const uint stride_z) {
    z[offset_z + get_global_id(0) * stride_z] =
        remainder(x[offset_x + get_global_id(0) * stride_x], y[offset_y + get_global_id(0) * stride_y]);
}

__kernel void vector_sqrt (__global const REAL* x, const uint offset_x, const uint stride_x,
                           __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = sqrt(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_inv_sqrt (__global const REAL* x, const uint offset_x, const uint stride_x,
                               __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = rsqrt(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_cbrt (__global const REAL* x, const uint offset_x, const uint stride_x,
                           __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = cbrt(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_inv_cbrt (__global const REAL* x, const uint offset_x, const uint stride_x,
                               __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = (REAL)1.0 / cbrt(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_pow2o3 (__global const REAL* x, const uint offset_x, const uint stride_x,
                             __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = pow(x[offset_x + get_global_id(0) * stride_x], REAL2o3);
}

__kernel void vector_pow3o2 (__global const REAL* x, const uint offset_x, const uint stride_x,
                             __global REAL* y, const uint offset_y, const uint stride_y) {
        y[offset_y + get_global_id(0) * stride_y] = powr(x[offset_x + get_global_id(0) * stride_x], REAL3o2);
}

__kernel void vector_pow (__global const REAL* x, const uint offset_x, const uint stride_x,
                          __global const REAL* y, const uint offset_y, const uint stride_y,
                          __global REAL* z, const uint offset_z, const uint stride_z) {
    z[offset_z + get_global_id(0) * stride_z] =
        pow(x[offset_x + get_global_id(0) * stride_x], y[offset_y + get_global_id(0) * stride_y]);
}

__kernel void vector_powx (__global const REAL* x, const uint offset_x, const uint stride_x,
                           const REAL b,
                           __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = pow(x[offset_x + get_global_id(0) * stride_x], b);
}

__kernel void vector_hypot (__global const REAL* x, const uint offset_x, const uint stride_x,
                            __global const REAL* y, const uint offset_y, const uint stride_y,
                            __global REAL* z, const uint offset_z, const uint stride_z) {
    const REAL xval = x[offset_y + get_global_id(0) * stride_y];
    const REAL yval = y[offset_y + get_global_id(0) * stride_y];
    z[offset_z + get_global_id(0) * stride_z] =
        sqrt(xval * xval + yval * yval);
}

__kernel void vector_exp (__global const REAL* x, const uint offset_x, const uint stride_x,
                          __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = exp(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_expm1 (__global const REAL* x, const uint offset_x, const uint stride_x,
                            __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = expm1(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_log (__global const REAL* x, const uint offset_x, const uint stride_x,
                          __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = log(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_log10 (__global const REAL* x, const uint offset_x, const uint stride_x,
                            __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = log10(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_sin (__global const REAL* x, const uint offset_x, const uint stride_x,
                          __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = sin(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_cos (__global const REAL* x, const uint offset_x, const uint stride_x,
                          __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = cos(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_tan (__global const REAL* x, const uint offset_x, const uint stride_x,
                          __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = tan(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_sincos (__global const REAL* x, const uint offset_x, const uint stride_x,
                             __global REAL* y, const uint offset_y, const uint stride_y,
                             __global REAL* z, const uint offset_z, const uint stride_z) {
    const REAL xval = x[offset_x + get_global_id(0) * stride_x];
    y[offset_y + get_global_id(0) * stride_y] = sin(xval);
    z[offset_z + get_global_id(0) * stride_z] = cos(xval);
}

__kernel void vector_asin (__global const REAL* x, const uint offset_x, const uint stride_x,
                           __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = asin(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_acos (__global const REAL* x, const uint offset_x, const uint stride_x,
                           __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = acos(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_atan (__global const REAL* x, const uint offset_x, const uint stride_x,
                           __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = atan(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_atan2 (__global const REAL* x, const uint offset_x, const uint stride_x,
                            __global const REAL* y, const uint offset_y, const uint stride_y,
                            __global REAL* z, const uint offset_z, const uint stride_z) {
    z[offset_z + get_global_id(0) * stride_z] =
        atan2(x[offset_x + get_global_id(0) * stride_x], y[offset_y + get_global_id(0) * stride_y]);
}

__kernel void vector_sinh (__global const REAL* x, const uint offset_x, const uint stride_x,
                           __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = sinh(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_cosh (__global const REAL* x, const uint offset_x, const uint stride_x,
                           __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = cosh(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_tanh (__global const REAL* x, const uint offset_x, const uint stride_x,
                           __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = tanh(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_asinh (__global const REAL* x, const uint offset_x, const uint stride_x,
                            __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = asinh(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_acosh (__global const REAL* x, const uint offset_x, const uint stride_x,
                            __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = acosh(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_atanh (__global const REAL* x, const uint offset_x, const uint stride_x,
                            __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = atanh(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_erf (__global const REAL* x, const uint offset_x, const uint stride_x,
                          __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = erf(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_erfc (__global const REAL* x, const uint offset_x, const uint stride_x,
                           __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = erfc(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_cdf_norm (__global const REAL* x, const uint offset_x, const uint stride_x,
                               __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] =
        (REAL)0.5 * ((REAL)1.0 +  erf((REAL)(x[offset_x + get_global_id(0) * stride_x] / M_SQRT2_F)));
}

__kernel void vector_gamma (__global const REAL* x, const uint offset_x, const uint stride_x,
                            __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = tgamma(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_lgamma (__global const REAL* x, const uint offset_x, const uint stride_x,
                             __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = lgamma(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_floor (__global const REAL* x, const uint offset_x, const uint stride_x,
                            __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = floor(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_ceil (__global const REAL* x, const uint offset_x, const uint stride_x,
                           __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = ceil(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_trunc (__global const REAL* x, const uint offset_x, const uint stride_x,
                            __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = trunc(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_round (__global const REAL* x, const uint offset_x, const uint stride_x,
                            __global REAL* y, const uint offset_y, const uint stride_y) {
    y[offset_y + get_global_id(0) * stride_y] = round(x[offset_x + get_global_id(0) * stride_x]);
}

__kernel void vector_modf (__global const REAL* x, const uint offset_x, const uint stride_x,
                           __global REAL* y, const uint offset_y, const uint stride_y,
                           __global REAL* z, const uint offset_z, const uint stride_z) {
    z[offset_z + get_global_id(0) * stride_z] =
        modf(x[offset_x + get_global_id(0) * stride_x], &y[offset_y + get_global_id(0) * stride_y]);
}

__kernel void vector_fmax (__global const REAL* x, const uint offset_x, const uint stride_x,
                           __global const REAL* y, const uint offset_y, const uint stride_y,
                           __global REAL* z, const uint offset_z, const uint stride_z) {
    const REAL xval = x[offset_x + get_global_id(0) * stride_x];
    const REAL yval = y[offset_y + get_global_id(0) * stride_y];
    z[offset_z + get_global_id(0) * stride_z] = xval < yval ? yval : xval;
}

__kernel void vector_fmin (__global const REAL* x, const uint offset_x, const uint stride_x,
                           __global const REAL* y, const uint offset_y, const uint stride_y,
                           __global REAL* z, const uint offset_z, const uint stride_z) {
    const REAL xval = x[offset_x + get_global_id(0) * stride_x];
    const REAL yval = y[offset_y + get_global_id(0) * stride_y];
    z[offset_z + get_global_id(0) * stride_z] = yval < xval ? yval : xval;
}

__kernel void ge_sqr (__global const REAL* a, const uint offset_a, const uint ld_a,
                      __global REAL* b, const uint offset_b, const uint ld_b) {
    const REAL aval = a[offset_a + get_global_id(0) + get_global_id(1) * ld_a];
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] = aval * aval;
}

__kernel void ge_mul (__global const REAL* a, const uint offset_a, const uint ld_a,
                      __global const REAL* b, const uint offset_b, const uint ld_b,
                      __global REAL* c, const uint offset_c, const uint ld_c) {
    c[offset_c + get_global_id(0) + get_global_id(1) * ld_c] =
        a[offset_a + get_global_id(0) + get_global_id(1) * ld_a] *
        b[offset_b + get_global_id(0) + get_global_id(1) * ld_b];
}

__kernel void ge_div (__global const REAL* a, const uint offset_a, const uint ld_a,
                      __global const REAL* b, const uint offset_b, const uint ld_b,
                      __global REAL* c, const uint offset_c, const uint ld_c) {
    c[offset_c + get_global_id(0) + get_global_id(1) * ld_c] =
        a[offset_a + get_global_id(0) + get_global_id(1) * ld_a] /
        b[offset_b + get_global_id(0) + get_global_id(1) * ld_b];
}

__kernel void ge_inv (__global const REAL* a, const uint offset_a, const uint ld_a,
                      __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        (REAL)1.0 / a[offset_a + get_global_id(0) + get_global_id(1) * ld_a];
}

__kernel void ge_abs (__global const REAL* a, const uint offset_a, const uint ld_a,
                      __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        fabs(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_linear_frac (__global const REAL* a, const uint offset_a, const uint ld_a,
                              __global const REAL* b, const uint offset_b, const uint ld_b,
                              const REAL scalea, const REAL shifta, const REAL scaleb, const REAL shiftb,
                              __global REAL* c, const uint offset_c, const uint ld_c) {
    c[offset_c + get_global_id(0) + get_global_id(1) * ld_c] =
        (scalea * a[offset_a + get_global_id(0) + get_global_id(1) * ld_a] + shifta) /
        (scaleb * b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] + shiftb);
}

__kernel void ge_scale_shift (__global const REAL* a, const uint offset_a, const uint ld_a,
                              const REAL scalea, const REAL shifta,
                              __global REAL* c, const uint offset_c, const uint ld_c) {
    c[offset_c + get_global_id(0) + get_global_id(1) * ld_c] =
        scalea * a[offset_a + get_global_id(0) + get_global_id(1) * ld_a] + shifta;

}

__kernel void ge_fmod (__global const REAL* a, const uint offset_a, const uint ld_a,
                       __global const REAL* b, const uint offset_b, const uint ld_b,
                       __global REAL* c, const uint offset_c, const uint ld_c) {
    c[offset_c + get_global_id(0) + get_global_id(1) * ld_c] =
        fmod(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a],
             b[offset_b + get_global_id(0) + get_global_id(1) * ld_b]);
}

__kernel void ge_frem (__global const REAL* a, const uint offset_a, const uint ld_a,
                       __global const REAL* b, const uint offset_b, const uint ld_b,
                       __global REAL* c, const uint offset_c, const uint ld_c) {
    c[offset_c + get_global_id(0) + get_global_id(1) * ld_c] =
        remainder(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a],
                  b[offset_b + get_global_id(0) + get_global_id(1) * ld_b]);
}

__kernel void ge_sqrt (__global const REAL* a, const uint offset_a, const uint ld_a,
                       __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        sqrt(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_inv_sqrt (__global const REAL* a, const uint offset_a, const uint ld_a,
                           __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        rsqrt(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_cbrt (__global const REAL* a, const uint offset_a, const uint ld_a,
                       __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        cbrt(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_inv_cbrt (__global const REAL* a, const uint offset_a, const uint ld_a,
                           __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        (REAL)1.0 / cbrt(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_pow2o3 (__global const REAL* a, const uint offset_a, const uint ld_a,
                         __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        pow(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a], REAL2o3);
}

__kernel void ge_pow3o2 (__global const REAL* a, const uint offset_a, const uint ld_a,
                         __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        pow(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a], REAL3o2);
}

__kernel void ge_pow (__global const REAL* a, const uint offset_a, const uint ld_a,
                      __global const REAL* b, const uint offset_b, const uint ld_b,
                      __global REAL* c, const uint offset_c, const uint ld_c) {
    c[offset_c + get_global_id(0) + get_global_id(1) * ld_c] =
        pow(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a],
            b[offset_b + get_global_id(0) + get_global_id(1) * ld_b]);
}

__kernel void ge_powx (__global const REAL* a, const uint offset_a, const uint ld_a,
                       const REAL b,
                       __global REAL* c, const uint offset_c, const uint ld_c) {
    c[offset_c + get_global_id(0) + get_global_id(1) * ld_c] =
        pow(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a], b);
}

__kernel void ge_hypot (__global const REAL* a, const uint offset_a, const uint ld_a,
                        __global const REAL* b, const uint offset_b, const uint ld_b,
                        __global REAL* c, const uint offset_c, const uint ld_c) {
    const REAL aval = a[offset_a + get_global_id(0) + get_global_id(1) * ld_a];
    const REAL bval = b[offset_b + get_global_id(0) + get_global_id(1) * ld_b];
    c[offset_c + get_global_id(0) + get_global_id(1) * ld_c] = sqrt(aval * aval + bval * bval);
}

__kernel void ge_exp (__global const REAL* a, const uint offset_a, const uint ld_a,
                      __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        exp(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_expm1 (__global const REAL* a, const uint offset_a, const uint ld_a,
                        __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        expm1(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_log (__global const REAL* a, const uint offset_a, const uint ld_a,
                      __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        log(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_log10 (__global const REAL* a, const uint offset_a, const uint ld_a,
                        __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        log10(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_sin (__global const REAL* a, const uint offset_a, const uint ld_a,
                      __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        sin(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_cos (__global const REAL* a, const uint offset_a, const uint ld_a,
                      __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        cos(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_tan (__global const REAL* a, const uint offset_a, const uint ld_a,
                      __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        tan(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_sincos (__global const REAL* a, const uint offset_a, const uint ld_a,
                         __global REAL* b, const uint offset_b, const uint ld_b,
                         __global REAL* c, const uint offset_c, const uint ld_c) {
    const REAL aval = a[offset_a + get_global_id(0) + get_global_id(1) * ld_a];
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] = sin(aval);
    c[offset_c + get_global_id(0) + get_global_id(1) * ld_c] = cos(aval);
}

__kernel void ge_asin (__global const REAL* a, const uint offset_a, const uint ld_a,
                       __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        asin(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_acos (__global const REAL* a, const uint offset_a, const uint ld_a,
                       __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        acos(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_atan (__global const REAL* a, const uint offset_a, const uint ld_a,
                       __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        atan(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_atan2 (__global const REAL* a, const uint offset_a, const uint ld_a,
                        __global const REAL* b, const uint offset_b, const uint ld_b,
                        __global REAL* c, const uint offset_c, const uint ld_c) {
    c[offset_c + get_global_id(0) + get_global_id(1) * ld_c] =
        atan2(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a],
              b[offset_b + get_global_id(0) + get_global_id(1) * ld_b]);
}

__kernel void ge_sinh (__global const REAL* a, const uint offset_a, const uint ld_a,
                       __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        sinh(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_cosh (__global const REAL* a, const uint offset_a, const uint ld_a,
                       __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        cosh(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_tanh (__global const REAL* a, const uint offset_a, const uint ld_a,
                       __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        tanh(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_asinh (__global const REAL* a, const uint offset_a, const uint ld_a,
                        __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        asinh(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_acosh (__global const REAL* a, const uint offset_a, const uint ld_a,
                        __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        acosh(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_atanh (__global const REAL* a, const uint offset_a, const uint ld_a,
                        __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        atanh(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_erf (__global const REAL* a, const uint offset_a, const uint ld_a,
                      __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        erf(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_erfc (__global const REAL* a, const uint offset_a, const uint ld_a,
                       __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        erfc(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_cdf_norm (__global const REAL* a, const uint offset_a, const uint ld_a,
                           __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        (REAL)0.5 * ((REAL)1.0 + erf(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a] / M_SQRT2_F));
}

__kernel void ge_gamma (__global const REAL* a, const uint offset_a, const uint ld_a,
                        __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        tgamma(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_lgamma (__global const REAL* a, const uint offset_a, const uint ld_a,
                         __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        lgamma(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_floor (__global const REAL* a, const uint offset_a, const uint ld_a,
                        __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        floor(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_ceil (__global const REAL* a, const uint offset_a, const uint ld_a,
                       __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        ceil(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_trunc (__global const REAL* a, const uint offset_a, const uint ld_a,
                        __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        trunc(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_round (__global const REAL* a, const uint offset_a, const uint ld_a,
                        __global REAL* b, const uint offset_b, const uint ld_b) {
    b[offset_b + get_global_id(0) + get_global_id(1) * ld_b] =
        round(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a]);
}

__kernel void ge_modf (__global const REAL* a, const uint offset_a, const uint ld_a,
                       __global const REAL* b, const uint offset_b, const uint ld_b,
                       __global REAL* c, const uint offset_c, const uint ld_c) {
    c[offset_c + get_global_id(0) + get_global_id(1) * ld_c] =
        modf(a[offset_a + get_global_id(0) + get_global_id(1) * ld_a],
             &b[offset_b + get_global_id(0) + get_global_id(1) * ld_b]);
}

__kernel void ge_fmax (__global const REAL* a, const uint offset_a, const uint ld_a,
                       __global const REAL* b, const uint offset_b, const uint ld_b,
                       __global REAL* c, const uint offset_c, const uint ld_c) {
    const REAL aval = a[offset_a + get_global_id(0) + get_global_id(1) * ld_a];
    const REAL bval = b[offset_b + get_global_id(0) + get_global_id(1) * ld_b];
    c[offset_c + get_global_id(0) + get_global_id(1) * ld_c] = aval < bval ? bval : aval;
}

__kernel void ge_fmin (__global const REAL* a, const uint offset_a, const uint ld_a,
                       __global const REAL* b, const uint offset_b, const uint ld_b,
                       __global REAL* c, const uint offset_c, const uint ld_c) {
    const REAL aval = a[offset_a + get_global_id(0) + get_global_id(1) * ld_a];
    const REAL bval = b[offset_b + get_global_id(0) + get_global_id(1) * ld_b];
    c[offset_c + get_global_id(0) + get_global_id(1) * ld_c] = bval < aval ? bval : aval;
}
