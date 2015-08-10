# coding: utf-8
# cython: boundscheck=False
# cython: nonecheck=False
# cython: cdivision=True
# cython: wraparound=False
# cython: profile=False

""" Basis Function Expansion in Cython """

from __future__ import division, print_function

__author__ = "adrn <adrn@astro.columbia.edu>"

import numpy as np
cimport numpy as np
from libc.math cimport M_PI

cdef extern from "math.h":
    double sqrt(double x) nogil
    double atan2(double y, double x) nogil
    double cos(double x) nogil
    double sin(double x) nogil

cdef extern from "gsl/gsl_sf_gamma.h":
    double gsl_sf_gamma(double x) nogil
    double gsl_sf_fact(unsigned int n) nogil

cdef extern from "src/coeff_helper.c":
    double RR_Plm_cosmphi(double r, double phi, double X, double a, int n, int l, int m) nogil

__all__ = ['Anlm_integrand']

cpdef Anlm_integrand(density_func, double phi, double X, double xsi,
                     int n, int l, int m,
                     double M, double r_s,
                     double[::1] args):
    """
    Anlm_integrand(density_func, phi, X, xsi, n, l, m, M, r_s, density_func_args)
    """
    cdef:
        double r = (1 + xsi) / (1 - xsi)
        double x = r * cos(phi) * sqrt(1-X*X)
        double y = r * sin(phi) * sqrt(1-X*X)
        double z = r * X

        double Knl, Inl, tmp, tmp2, krond

    Knl = 0.5*n*(n + 4*l + 3) + (l + 1)*(2*l + 1)
    tmp2 = (gsl_sf_gamma(n + 4*l + 3) / (gsl_sf_fact(n) *
            (n + 2*l + 1.5) * gsl_sf_gamma(2*l + 1.5)**2))
    if m == 0:
        krond = 1.
    else:
        krond = 0.

    Inl = (Knl / 2**(8*l+6) * tmp2 * (1 + krond) * M_PI *
           2/(2*l+1) * gsl_sf_fact(l+m) / gsl_sf_fact(l-m))
    tmp = 2. / ((1-xsi)*(1-xsi))
    return (RR_Plm_cosmphi(r, phi, X, r_s, n, l, m) * tmp / Inl *
            density_func(x, y, z, M, r_s, args) / M)

cpdef compute_Anlm(density_func, nlm, M, r_s, args=()):
    cdef:
        double[::1] _nlm = np.array(nlm)
        double[::1] _args = np.array(args)

    Anlm_integrand(density_func,
                   0., 0., 0.,
                   nlm[0], nlm[1], nlm[2],
                   M, r_s,
                   _args)













# cpdef phi_nlm(double r, double phi, double costheta, int n, int l, int m):
#     cdef double A,B
#     A = s**l / (1+s)**(2*l+1) * gsl_sf_gegenpoly_n(n, 2*l + 1.5, (s-1)/(s+1))
#     B = gsl_sf_legendre_Plm(l, m, costheta)
#     return -A * B * cos(m*phi)

# cpdef rho_nlm(double s, double phi, double costheta, int n, int l, int m):
#     cdef double A,B,Knl
#     Knl = 0.5*n*(n+4*l+3) + (l+1)*(2*l+1)
#     A = Knl/(2*M_PI) * s**l / (s*(1+s)**(2*l+3)) * gsl_sf_gegenpoly_n(n, 2*l + 1.5, (s-1)/(s+1))
#     B = gsl_sf_legendre_Plm(l, m, costheta)
#     return A * B * cos(m*phi)

# cpdef apw_value(double[::1] xyz,
#                 double G, double M, double r_s,
#                 double[:,:,::1] Anlm, int nmax, int lmax):
#     cdef:
#         double r = sqrt(xyz[0]*xyz[0] + xyz[1]*xyz[1] + xyz[2]*xyz[2])
#         double s = r / r_s
#         double costheta = xyz[2]/r
#         double phi = atan2(xyz[1], xyz[0])
#         int n,l,m
#         double pot = 0.

#     for n in range(nmax+1):
#         for l in range(lmax+1):
#             for m in range(-l,l+1):
#                 pot += Anlm[n,l,m] * phi_nlm(s, phi, costheta, n, l, m)

#     return G*M/r_s * pot

# cpdef apw_density(double[::1] xyz,
#                   double G, double M, double r_s,
#                   double[:,:,::1] Anlm, int nmax, int lmax):
#     cdef:
#         double r = sqrt(xyz[0]*xyz[0] + xyz[1]*xyz[1] + xyz[2]*xyz[2])
#         double s = r / r_s
#         double costheta = xyz[2]/r
#         double phi = atan2(xyz[1], xyz[0])
#         int n,l,m
#         double dens = 0.

#     for n in range(nmax+1):
#         for l in range(lmax+1):
#             for m in range(-l,l+1):
#                 dens += Anlm[n,l,m] * rho_nlm(s, phi, costheta, n, l, m)

#     return M/(4*M_PI*r_s*r_s*r_s) * dens
