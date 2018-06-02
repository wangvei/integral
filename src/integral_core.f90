! integral_core.f90

module integral_core
    use, intrinsic :: iso_fortran_env, only : int32, real64
    use ferror
    implicit none
    private
    public :: INT_OUT_OF_MEMORY_ERROR
    public :: INT_COUNT_EXCEEDED_ERROR
    public :: INT_ROUND_OFF_ERROR
    public :: INT_INTEGRAND_BEHAVIOR_ERROR
    public :: INT_CONVERGENCE_ERROR
    public :: INT_DIVERGENT_ERROR
    public :: INT_INVALID_INPUT_ERROR
    public :: INT_15_POINT_RULE
    public :: INT_21_POINT_RULE
    public :: INT_31_POINT_RULE
    public :: INT_41_POINT_RULE
    public :: INT_51_POINT_RULE
    public :: INT_61_POINT_RULE
    public :: integrand
    public :: integration_behavior
    public :: integrator_base
    public :: finite_interval_integrator
    public :: finite_interval_fcn
    public :: adaptive_integrator
    public :: nonadaptive_integrator

! ------------------------------------------------------------------------------
    !> @brief An error flag indicating insufficient memory.
    integer(int32), parameter :: INT_OUT_OF_MEMORY_ERROR = 1
    !> @brief An error flag indicates a specific parameter count has been
    !!  exceeded.
    integer(int32), parameter :: INT_COUNT_EXCEEDED_ERROR = 2
    !> @brief An error flag indicating round off error has become an issue.
    integer(int32), parameter :: INT_ROUND_OFF_ERROR = 3
    !> @brief An error flag indicating difficult integrand behavior.
    integer(int32), parameter :: INT_INTEGRAND_BEHAVIOR_ERROR = 4
    !> @brief An error flag indicating convergence issues.
    integer(int32), parameter :: INT_CONVERGENCE_ERROR = 5
    !> @brief An error flag indicating divergent behavior.
    integer(int32), parameter :: INT_DIVERGENT_ERROR = 6
    !> @brief An error flag indicating an invalid input.
    integer(int32), parameter :: INT_INVALID_INPUT_ERROR = 7

! ------------------------------------------------------------------------------
    !> @brief Defines a 15-point Gauss-Kronrod integration rule.
    integer(int32), parameter :: INT_15_POINT_RULE = 15
    !> @brief Defines a 21-point Gauss-Kronrod integration rule.
    integer(int32), parameter :: INT_21_POINT_RULE = 21
    !> @brief Defines a 31-point Gauss-Kronrod integration rule.
    integer(int32), parameter :: INT_31_POINT_RULE = 31
    !> @brief Defines a 41-point Gauss-Kronrod integration rule.
    integer(int32), parameter :: INT_41_POINT_RULE = 41
    !> @brief Defines a 51-point Gauss-Kronrod integration rule.
    integer(int32), parameter :: INT_51_POINT_RULE = 51
    !> @brief Defines a 61-point Gauss-Kronrod integration rule.
    integer(int32), parameter :: INT_61_POINT_RULE = 61

! ------------------------------------------------------------------------------
    interface
        !> @brief Defines a function of one variable to be integrated.
        !!
        !! @param[in] x The value of the independent variable at which to
        !!  evaluate the function.
        !! @return The value of the function at @p x.
        function integrand(x) result(f)
            use, intrinsic :: iso_fortran_env, only : real64
            real(real64), intent(in) :: x
            real(real64) :: f
        end function
    end interface

! ------------------------------------------------------------------------------
    !> @brief Provides information regarding the behavior of an integrator.
    type integration_behavior
        !> @brief An estimate of the absolute error of the integration process.
        real(real64) :: error_estimate
        !> @brief The number of integrand evaluations.
        integer(int32) :: evaluation_count
        !> @brief The number of subintervals into which the integration region
        !! was divided.
        integer(int32) :: subinterval_count
    end type

! ******************************************************************************
! INTEGRAL_INTEGRATOR_BASE.F90
! ------------------------------------------------------------------------------
    !> @brief Defines a base type for integrator types.
    type integrator_base
    private
        !> @brief The absolute tolerance.
        real(real64) :: m_absTol = 1.0d-8
        !> @brief The relative tolerance.
        real(real64) :: m_relTol = 1.0d-8
        !> @brief The maximum number of subintervals.
        integer(int32) :: m_maxInt = 10
    contains
        !> @brief Gets the absolute tolerance value.
        !!
        !! @par Syntax
        !! @code{.f90}
        !! pure real(real64) function get_abs_tol(class(integrator_base) this)
        !! @endcode
        !!
        !! @param[in] this The integrator_base object.
        !! @return The tolerance value.
        procedure, public :: get_abs_tol => ib_get_abs_tol
        !> @brief Sets the absolute tolerance value.
        !!
        !! @par Syntax
        !! @code{.f90}
        !! subroutine set_abs_tol(class(integrator_base) this, real(real64) x)
        !! @endcode
        !!
        !! @param[in,out] this The integrator_base object.
        !! @param[in] The tolerance value.
        procedure, public :: set_abs_tol => ib_set_abs_tol
        !> @brief Gets the relative tolerance value.
        !!
        !! @par Syntax
        !! @code{.f90}
        !! pure real(real64) function get_rel_tol(class(integrator_base) this)
        !! @endcode
        !!
        !! @param[in] this The integrator_base object.
        !! @return The tolerance value.
        procedure, public :: get_rel_tol => ib_get_rel_tol
        !> @brief Sets the relative tolerance value.
        !!
        !! @par Syntax
        !! @code{.f90}
        !! subroutine set_rel_tol(class(integrator_base) this, real(real64) x)
        !! @endcode
        !!
        !! @param[in,out] this The integrator_base object.
        !! @param[in] The tolerance value.
        procedure, public :: set_rel_tol => ib_set_rel_tol
        !> @brief Gets the maximum number of subintervals into which the
        !! integrator may divide the problem region.
        !!
        !! @par Syntax
        !! @code{.f90}
        !! pure integer(int32) function get_max_subintervals(class(integrator_base) this)
        !! @endcode
        !!
        !! @param[in] this The integrator_base object.
        !! @return The number of intervals.
        procedure, public :: get_max_subintervals => ib_get_max_subintervals
        !> @brief Sets the maximum number of subintervals into which the
        !! integrator may divide the problem region.
        !!
        !! @par Syntax
        !! @code{.f90}
        !! subroutine set_max_subintervals(class(integrator_base) this, integer(int32) x)
        !! @endcode
        !!
        !! @param[in,out] this The integrator_base object.
        !! @param[in] x The number of intervals.
        procedure, public :: ib_set_max_subintervals => ib_set_max_subintervals
    end type

! ------------------------------------------------------------------------------
    interface
        pure module function ib_get_abs_tol(this) result(x)
            class(integrator_base), intent(in) :: this
            real(real64) :: x
        end function

        module subroutine ib_set_abs_tol(this, x)
            class(integrator_base), intent(inout) :: this
            real(real64), intent(in) :: x
        end subroutine

        pure module function ib_get_rel_tol(this) result(x)
            class(integrator_base), intent(in) :: this
            real(real64) :: x
        end function

        module subroutine ib_set_rel_tol(this, x)
            class(integrator_base), intent(inout) :: this
            real(real64), intent(in) :: x
        end subroutine

        pure module function ib_get_max_subintervals(this) result(x)
            class(integrator_base), intent(in) :: this
            integer(int32) :: x
        end function

        module subroutine ib_set_max_subintervals(this, x)
            class(integrator_base), intent(inout) :: this
            integer(int32), intent(in) :: x
        end subroutine
    end interface

! ******************************************************************************
    !> @brief A type that defines an integrator meant to operate on integrands
    !! over a finite region.
    type, abstract, extends(integrator_base) :: finite_interval_integrator
    contains
        !> @brief Performs the actual integration.
        procedure(finite_interval_fcn), public, deferred, pass :: integrate
    end type

    interface
        !> @brief Defines the signature of a routine used to integrate
        !! a function of one variable over a finite interval.
        !!
        !! @param[in,out] this The finite_interval_integrator object.
        !! @param[in] fcn The integrand.
        !! @param[in] a The lower limit of integration.
        !! @param[in] b The upper limit of integration.
        !! @param[out] info An optional output providing information regarding
        !!  behavior of the integrator.
        !! @param[out] err An optional argument that may be used to provide
        !!  customized error handling behaviors.
        !! @return The value of the integral over the specified range.
        function finite_interval_fcn(this, fcn, a, b, info, err) result(rst)
            use, intrinsic :: iso_fortran_env, only : real64
            use ferror
            import finite_interval_integrator
            import integrand
            import integration_behavior
            class(finite_interval_integrator), intent(inout) :: this
            procedure(integrand), intent(in), pointer :: fcn
            real(real64), intent(in) :: a, b
            type(integration_behavior), intent(out), optional :: info
            class(errors), intent(inout), optional, target :: err
            real(real64) :: rst
        end function
    end interface

! ******************************************************************************
! INTEGRAL_ADAPTIVE_INTEGRATOR.F90
! ------------------------------------------------------------------------------
    !> @brief Defines an integrator that uses an adaptive Gauss-Kronrod method
    !! to compute the integral of a function of one variable over a finite
    !! interval.
    type, extends(finite_interval_integrator) :: adaptive_integrator
    private
        !> @brief A workspace array.
        real(real64), allocatable, dimension(:) :: m_work
        !> @brief A workspace array.
        integer(int32), allocatable, dimension(:) :: m_iwork
        !> @brief True for user defined breakpoints; else, false.
        logical :: m_userDefinedBreaks = .false.
        !> @brief A list of user-defined breakpoints.
        real(real64), allocatable, dimension(:) :: m_breakpoints
    contains
        !> @brief Initializes the adaptive_integrator object.
        !!
        !! @par Syntax
        !! @code{.f90}
        !! subroutine initialize(class(adaptive_integrator) this, optional class(errors) err)
        !! @endcode
        !!
        !! @param[in] this The adaptive_integrator object.
        !! @param[in,out] err An optional output that can be used to provide
        !!  an error handling mechanism.  If not provided, a default error
        !!  handling mechanism will be utilized.  Possible errors that may
        !!  be encountered are as follows.
        !!  - INT_OUT_OF_MEMORY_ERROR: There is insufficient memory available to
        !!      complete this operation.
        procedure, public :: initialize => ai_init
        !> @brief Performs the actual integration.
        !!
        !! @par Syntax
        !! @code{.f90}
        !! real(real64) function integrate(class(adaptive_integrator) this, procedure(integrand) pointer fcn, real(real64) a, real(real64) b, optional type(integration_behavior) info, optional class(errors) err)
        !! @endcode
        !!
        !! @param[in,out] this The adaptive_integrator object.
        !! @param[in] fcn The integrand.
        !! @param[in] a The lower limit of integration.
        !! @param[in] b The upper limit of integration.
        !! @param[out] info An optional output providing information regarding
        !!  behavior of the integrator.
        !! @param[in,out] err An optional output that can be used to provide
        !!  an error handling mechanism.  If not provided, a default error
        !!  handling mechanism will be utilized.  Possible errors that may
        !!  be encountered are as follows.
        !!  - INT_OUT_OF_MEMORY_ERROR: There is insufficient memory available to
        !!      complete this operation.
        !!
        !! @return The value of the integral over the specified range.
        !!
        !! @par Remarks
        !! This routine utilizes the QUADPACK routine QAGS.  For more
        !! information on this routine see http://www.netlib.org/quadpack/.
        procedure, public :: integrate => ai_integrate
        !> @brief Gets a flag determining if user-defined breakpoints should
        !! be used to inform the integrator of points of difficulty within
        !! the integration region.
        !!
        !! @par Syntax
        !! @code{.f90}
        !! pure logical function get_use_breakpoints(class(adaptive_integrator) this)
        !! @endcode
        !!
        !! @param[in] this The adaptive_integrator object.
        !! @return Returns true if the user-defined breakpoints should be
        !!  used; else, false.
        procedure, public :: get_use_breakpoints => ai_get_use_brkpnts
        !> @brief Sets a flag determining if user-defined breakpoints should
        !! be used to inform the integrator of points of difficulty within
        !! the integration region.
        !!
        !! @par Syntax
        !! @code{.f90}
        !! subroutine set_use_breakpoints(class(adaptive_integrator) this, logical x)
        !! @endcode
        !!
        !! @param[in,out] this The adaptive_integrator object.
        !! @param[in] x Set to true if the user-defined breakpoints should be
        !!  used; else, set to false.
        procedure, public :: set_use_breakpoints => ai_set_use_brkpnts
        !> @brief Gets an array of user-defined breakpoints.
        !!
        !! @par Syntax
        !! @code{.f90}
        !! real(real64)(:) allocatable function get_breakpoints(class(adaptive_integrator) this)
        !! @endcode
        !!
        !! @param[in] this The adaptive_integrator object.
        !! @return The array of points.  This array will not be allocated if
        !!  no points have been defined.
        procedure, public :: get_breakpoints => ai_get_breakpoints
        !> @brief Sets an array of user-defined breakpoints.  Additionally,
        !! this array call set_use_breakpoints with an argument of true such
        !! that the integrator will use the breakpoints defined by this routine.
        !!
        !! @par Syntax
        !! @code{.f90}
        !! subroutine set_breakpoints(class(adaptive_integrator) this, real(real64) x(:))
        !! @endcode
        !!
        !! @param[in,out] this The adaptive_integrator object.
        !! @param[in] x The array of breakpoints.  Notice, each point must lie
        !!  within the integration interval.
        procedure, public :: set_breakpoints => ai_set_breakpoints
    end type

! ------------------------------------------------------------------------------
    interface
        module subroutine ai_init(this, err)
            class(adaptive_integrator), intent(inout) :: this
            class(errors), intent(inout), optional, target :: err
        end subroutine

        module function ai_integrate(this, fcn, a, b, info, err) result(rst)
            class(adaptive_integrator), intent(inout) :: this
            procedure(integrand), intent(in), pointer :: fcn
            real(real64), intent(in) :: a, b
            type(integration_behavior), intent(out), optional :: info
            class(errors), intent(inout), optional, target :: err
            real(real64) :: rst
        end function

        pure module function ai_get_use_brkpnts(this) result(x)
            class(adaptive_integrator), intent(in) :: this
            logical :: x
        end function

        module subroutine ai_set_use_brkpnts(this, x)
            class(adaptive_integrator), intent(inout) :: this
            logical, intent(in) :: x
        end subroutine

        module function ai_get_breakpoints(this) result(x)
            class(adaptive_integrator), intent(in) :: this
            real(real64), allocatable, dimension(:) :: x
        end function

        module subroutine ai_set_breakpoints(this, x)
            class(adaptive_integrator), intent(inout) :: this
            real(real64), intent(in), dimension(:) :: x
        end subroutine
    end interface

! ******************************************************************************
! INTEGRAL_NONADAPTIVE_INTEGRATOR.F90
! ------------------------------------------------------------------------------
    !>
    type, extends(finite_interval_integrator) :: nonadaptive_integrator
    private
        !> @brief The integration rule to use.
        integer(int32) :: m_rule = INT_15_POINT_RULE
    contains
        procedure, public :: integrate => ni_integrate
        procedure, public :: get_rule => ni_get_rule
        procedure, public :: set_rule => ni_set_rule
    end type

! ------------------------------------------------------------------------------
    interface
        module function ni_integrate(this, fcn, a, b, info, err) result(rst)
            class(nonadaptive_integrator), intent(inout) :: this
            procedure(integrand), intent(in), pointer :: fcn
            real(real64), intent(in) :: a, b
            type(integration_behavior), intent(out), optional :: info
            class(errors), intent(inout), optional, target :: err
            real(real64) :: rst
        end function

        pure module function ni_get_rule(this) result(x)
            class(nonadaptive_integrator), intent(in) :: this
            integer(int32) :: x
        end function

        module subroutine ni_set_rule(this, x, err)
            class(nonadaptive_integrator), intent(inout) :: this
            integer(int32), intent(in) :: x
            class(errors), intent(inout), optional, target :: err
        end subroutine
    end interface

! ******************************************************************************
end module
