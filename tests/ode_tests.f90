! ode_tests.f90

module ode_tests
    use iso_fortran_env
    use integral_core
    implicit none

contains
! ------------------------------------------------------------------------------
    ! Test Problem #1
    ! x" + 2 * z * wn * x' + wn**2 * x = 0
    !
    ! Solution (z < 1):
    ! x(t) = exp(-wn * z * t) * (C1 * cos(a * t) + C2 * sin(a * t))
    ! x'(t) = exp(-wn * z * t) * (a * (C2 * cos(a * t) - C1 * sin(a * t)) - ...
    !   wn * z * (C1 * cos(a * t) + C2 * sin(a * t)))
    !
    ! If:
    ! x(0) = 1
    ! x'(0) = 0
    !
    ! Then:
    ! C1 = 1
    ! C2 = wn * z / a
    !
    ! Where: a = wn * sqrt(1 - z**2)
    function ode_ans1(z, wn, t) result(x)
        ! Arguments
        real(real64), intent(in) :: z, wn, t
        real(real64) :: x(2), a, C1, C2
        a = wn * sqrt(1.0d0 - z**2)
        C1 = 1.0d0
        C2 = wn * z / a
        x(1) = exp(-wn * z * t) * (C1 * cos(a * t) + C2 * sin(a * t))
        x(2) = exp(-wn * z * t) * (a * (C2 * cos(a * t) - C1 * sin(a * t)) - &
            wn * z * (C1 * cos(a * t) + C2 * sin(a * t)))
    end function

! ------------------------------------------------------------------------------
    subroutine ode_test_fcn_1(x, y, dydx)
        ! Arguments
        real(real64), intent(in) :: x
        real(real64), intent(in), dimension(:) :: y
        real(real64), intent(out), dimension(:) :: dydx

        ! Parameters
        real(real64), parameter :: z = 0.2d0
        real(real64), parameter :: wn = 2.5d2

        ! Equations
        dydx(1) = y(2)
        dydx(2) = -(2.0d0 * z * wn * y(2) + wn**2 * y(1))
    end subroutine

! ------------------------------------------------------------------------------
    ! Force the integrator to only return output at the requested end point
    function ode_step_test_1() result(rst)
        ! Parameters
        real(real64), parameter :: z = 0.2d0
        real(real64), parameter :: wn = 2.5d2
        real(real64), parameter :: tol = 1.0d-4

        ! Local variables
        logical :: rst, brk
        type(ode_helper) :: obj
        type(ode_auto) :: integrator
        procedure(ode_fcn), pointer :: fcn
        real(real64) :: x(2), t, tout, rtol(2), atol(2), ans(2)

        ! Initialization
        rst = .true.

        ! Set up the integrator
        fcn => ode_test_fcn_1
        call obj%define_equations(2, fcn)
        call integrator%set_provide_all_output(.false.)

        ! Set up solution tolerances
        rtol = 1.0d-6
        atol = 1.0d-8

        ! Set up the initial conditions
        t = 0.0d0
        x = [1.0d0, 0.0d0]

        ! Compute one step
        tout = 1.0d-1
        brk = integrator%step(obj, t, x, tout, rtol, atol)

        ! Compute the solution at t
        ans = ode_ans1(z, wn, t)

        ! Test the results
        if (abs(x(1) - ans(1)) > tol) then
            rst = .false.
            print '(AEN12.3AEN12.3A)', "ODE Step Test 1 Failed.  Expected ", &
                ans(1), ", but found ", x(1), "."
        end if

        if (abs(x(2) - ans(2)) > tol) then
            rst = .false.
            print '(AEN12.3AEN12.3A)', &
                "ODE Step Test 1 Failed (Derivative).  Expected ", &
                ans(2), ", but found ", x(2), "."
        end if
    end function

! ------------------------------------------------------------------------------
    ! Force the integrator to only return output wherever it first succeeds
    function ode_step_test_2() result(rst)
        ! Parameters
        real(real64), parameter :: z = 0.2d0
        real(real64), parameter :: wn = 2.5d2
        real(real64), parameter :: tol = 1.0d-4

        ! Local variables
        logical :: rst, brk
        type(ode_helper) :: obj
        type(ode_auto) :: integrator
        procedure(ode_fcn), pointer :: fcn
        real(real64) :: x(2), t, tout, rtol(2), atol(2), ans(2)

        ! Initialization
        rst = .true.

        ! Set up the integrator
        fcn => ode_test_fcn_1
        call obj%define_equations(2, fcn)

        ! Set up solution tolerances
        rtol = 1.0d-6
        atol = 1.0d-8

        ! Set up the initial conditions
        t = 0.0d0
        x = [1.0d0, 0.0d0]

        ! Compute one step
        tout = 1.0d-1
        brk = integrator%step(obj, t, x, tout, rtol, atol)

        ! Compute the solution at t
        ans = ode_ans1(z, wn, t)

        ! Test the results
        if (abs(x(1) - ans(1)) > tol) then
            rst = .false.
            print '(AEN12.3AEN12.3A)', "ODE Step Test 2 Failed.  Expected ", &
                ans(1), ", but found ", x(1), "."
        end if

        if (abs(x(2) - ans(2)) > tol) then
            rst = .false.
            print '(AEN12.3AEN12.3A)', &
                "ODE Step Test 2 Failed (Derivative).  Expected ", &
                ans(2), ", but found ", x(2), "."
        end if
    end function

! ------------------------------------------------------------------------------
    ! Specifiy solution points
    function ode_test_1() result(rst)
        ! Local Variables
        logical :: rst

        ! Parameters
        real(real64), parameter :: tstart = 0.0d0
        real(real64), parameter :: tend = 1.0d0
        integer(int32), parameter :: npts = 100
        real(real64), parameter :: tol = 1.0d-4
        real(real64), parameter :: z = 0.2d0
        real(real64), parameter :: wn = 2.5d2

        ! More Variables
        integer(int32) :: i
        type(ode_helper) :: obj
        type(ode_auto) :: integrator
        procedure(ode_fcn), pointer :: fcn
        real(real64) :: ic(2), dt, t(npts), ans(2)
        real(real64), allocatable, dimension(:,:) :: x

        ! Initialization
        rst = .true.

        ! Build the time vector
        dt = (tend - tstart) / (npts - 1.0d0)
        t(1) = tstart
        do i = 2, npts
            t(i) = t(i-1) + dt
        end do

        ! Set up the integrator
        fcn => ode_test_fcn_1
        call obj%define_equations(2, fcn)
        call integrator%set_provide_all_output(.false.)

        ! Define the initial conditions
        ic = [1.0d0, 0.0d0]

        ! Compute the solution at each time point
        x = integrator%integrate(obj, t, ic)

        ! Check the solution
        do i = 1, size(x, 1)
            ans = ode_ans1(z, wn, x(i,1))

            if (abs(x(i,2) - ans(1)) > tol) then
                rst = .false.
                print '(AEN12.3AEN12.3AEN12.3)', &
                    "ODE Test 1 Failed.  Time = ", x(i,1), ", Expected: ", &
                    ans(1), ", Found: ", x(i,2)
            end if

            if (abs(x(i,3) - ans(2)) > tol) then
                rst = .false.
                print '(AEN12.3AEN12.3AEN12.3)', &
                    "ODE Test 1 Failed (Derivative).  Time = ", x(i,1), &
                    ", Expected: ", ans(2), ", Found: ", x(i,3)
            end if
        end do
    end function

    ! ------------------------------------------------------------------------------
        ! Let the integrator choose solution points
        function ode_test_2() result(rst)
            ! Local Variables
            logical :: rst

            ! Parameters
            real(real64), parameter :: tstart = 0.0d0
            real(real64), parameter :: tend = 1.0d0
            real(real64), parameter :: tol = 1.0d-3
            real(real64), parameter :: z = 0.2d0
            real(real64), parameter :: wn = 2.5d2

            ! More Variables
            integer(int32) :: i
            type(ode_helper) :: obj
            type(ode_auto) :: integrator
            procedure(ode_fcn), pointer :: fcn
            real(real64) :: ic(2), t(2), ans(2)
            real(real64), allocatable, dimension(:,:) :: x

            ! Initialization
            rst = .true.

            ! Build the time vector
            t = [tstart, tend]

            ! Set up the integrator
            fcn => ode_test_fcn_1
            call obj%define_equations(2, fcn)

            ! Define the initial conditions
            ic = [1.0d0, 0.0d0]

            ! Compute the solution at each time point
            x = integrator%integrate(obj, t, ic)

            ! Check the solution
            do i = 1, size(x, 1)
                ans = ode_ans1(z, wn, x(i,1))

                if (abs(x(i,2) - ans(1)) > tol) then
                    rst = .false.
                    print '(AEN12.3AEN12.3AEN12.3)', &
                        "ODE Test 2 Failed.  Time = ", x(i,1), ", Expected: ", &
                        ans(1), ", Found: ", x(i,2)
                end if

                if (abs(x(i,3) - ans(2)) > tol) then
                    rst = .false.
                    print '(AEN12.3AEN12.3AEN12.3)', &
                        "ODE Test 2 Failed (Derivative).  Time = ", x(i,1), &
                        ", Expected: ", ans(2), ", Found: ", x(i,3)
                end if
            end do
        end function

end module
