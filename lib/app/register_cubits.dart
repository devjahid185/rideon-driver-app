import 'package:ride_on_driver/data/repositories/auth_repository.dart';
import 'package:ride_on_driver/data/repositories/dashborad_repository.dart';
import 'package:ride_on_driver/data/repositories/food_delivery_repository.dart';
import 'package:ride_on_driver/data/repositories/history_repository.dart';
import 'package:ride_on_driver/data/repositories/payment_repository.dart';
import 'package:ride_on_driver/data/repositories/profile_repository.dart';
import 'package:ride_on_driver/data/repositories/realtime_repository.dart';
import 'package:ride_on_driver/data/repositories/register_vehicle.dart';
import 'package:ride_on_driver/data/repositories/review_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';
import 'package:ride_on_driver/presentation/cubits/sos_cubit.dart';

import '../presentation/cubits/account/delete_account_cubit.dart';
import '../presentation/cubits/account/update_profile_cubit.dart';
import '../presentation/cubits/auth/change_email_cubit.dart';
import '../presentation/cubits/auth/change_phone_number_cubit.dart';
import '../presentation/cubits/auth/email_otp_cubit.dart';
import '../presentation/cubits/auth/login_cubit.dart';
import '../presentation/cubits/auth/otp_verify_cubit.dart';
import '../presentation/cubits/auth/resend_otp_cubit.dart';
import '../presentation/cubits/auth/set_locally_data_cubit.dart';
import '../presentation/cubits/auth/signup_cubit.dart';
import '../presentation/cubits/auth/user_authenticate_cubit.dart';
import '../presentation/cubits/bottom_bar_cubit.dart';
import '../presentation/cubits/dashboard/dashboard_cubit.dart';
import '../presentation/cubits/food_delivery_cubit.dart';
import '../presentation/cubits/general_cubit.dart';
import '../presentation/cubits/history/history_cubit.dart';
import '../presentation/cubits/localizations_cubit.dart';
 import '../presentation/cubits/location/get_polyline_cubit.dart';
import '../presentation/cubits/location/location_cubit.dart';
import '../presentation/cubits/logout_cubit.dart';
import '../presentation/cubits/payment/earning_cubit.dart';
import '../presentation/cubits/payment/payment_cubit.dart';
import '../presentation/cubits/payment/payment_method_cubit.dart';
import '../presentation/cubits/payment/wallet_cubit.dart';
import '../presentation/cubits/payment/wallet_data_cubit.dart';
import '../presentation/cubits/realtime/listen_ride_request_booking_id_cubit.dart';
import '../presentation/cubits/realtime/listen_ride_request_cubit.dart';
import '../presentation/cubits/realtime/manage_driver_cubit.dart';
import '../presentation/cubits/realtime/ride_status_cubit.dart';
import '../presentation/cubits/register_vehicle/get_vehicle_data.dart';
import '../presentation/cubits/register_vehicle/make_model_cubit.dart';
import '../presentation/cubits/register_vehicle/profile_cubit.dart';
import '../presentation/cubits/register_vehicle/register_vehicle_document.dart';
import '../presentation/cubits/register_vehicle/single_image_upload_cubit.dart';
import '../presentation/cubits/register_vehicle/vehicle_register_cubit.dart';
import '../presentation/cubits/review/review_cubit.dart';
import '../presentation/cubits/static_page.dart';

class RegisterCubits {
  List<SingleChildWidget> providers = [
    BlocProvider(create: (context) => LanguageCubit()),
    BlocProvider(create: (context) => LCodeCubit()),
    BlocProvider(create: (context) => AuthLoginCubit(AuthRepository())),
    BlocProvider(create: (context) => AuthSignUpCubit(AuthRepository())),
    BlocProvider(create: (context) => AuthResendOtpCubit(AuthRepository())),
    BlocProvider(create: (context) => AuthOtpVerifyCubit(AuthRepository())),
    BlocProvider(
        create: (context) => AuthUserAuthenticateCubit(AuthRepository())),
    BlocProvider(
        create: (context) =>
            RegisterProfileCubits(RegisterVehicleRepository())),
    BlocProvider(
        create: (context) => GetVehicleDataCubit(RegisterVehicleRepository())),
    BlocProvider(
        create: (context) =>
            GetItemVehicleDataCubit(RegisterVehicleRepository())),
    BlocProvider(
        create: (context) => MakeModelCubit(RegisterVehicleRepository())),
    BlocProvider(create: (context) => ModelCubit()),
    BlocProvider(create: (context) => SelectedCubit()),
    BlocProvider(create: (context) => CheckSelectedCubit()),
    BlocProvider(create: (context) => LicenseSelectionCubit()),
    BlocProvider(create: (context) => CheckUpdatedLicenceImage()),
    BlocProvider(create: (context) => CheckUpdatedDocumentImage()),
    BlocProvider(create: (context) => UpdateImage()),
    BlocProvider(create: (context) => CheckUpdatedImage()),
    BlocProvider(create: (context) => UpdateImageCommon()),
    BlocProvider(create: (context) => UpdateDocImageCommon()),
    BlocProvider(create: (context) => UpdateDocImageStatusCommon()),
    BlocProvider(create: (context) => UpdateImageCommonBase64Img()),
    BlocProvider(create: (context) => UpdateDocImage()),
    BlocProvider(create: (context) => UpdateLicenceImage()),
    BlocProvider(create: (context) => UpdateLicenceImage2()),
    BlocProvider(create: (context) => DriverLicenseImageCubit()),
    BlocProvider(create: (context) => DriverIdImageCubit()),
    BlocProvider(
        create: (context) => VehicleRegisterCubit(RegisterVehicleRepository())),
    BlocProvider(create: (context) => MetaDataMap()),
    BlocProvider(create: (context) => AddItemMap()),
    BlocProvider(create: (context) => GetCurrentLocationCubit()),
    BlocProvider(create: (context) => GetItemIdCubit()),
    BlocProvider(create: (context) => VehicleFormCubit()),
    BlocProvider(create: (context) => GetDocVehicleFormCubit()),
    BlocProvider(create: (context) => SetCountryCubit()),
    BlocProvider(create: (context) => LogoutCubit()),
    BlocProvider(
        create: (context) =>
            RegisterVehicleDocumentCubit(RegisterVehicleRepository())),
    BlocProvider(
        create: (context) =>
            GetVehicleDocumentCubit(RegisterVehicleRepository())),
    BlocProvider(
        create: (context) =>
            SingleImageUploadCubits(RegisterVehicleRepository())),
    BlocProvider(create: (context) => ListenRideRequestCubit()),
    BlocProvider(create: (context) => UpdateDriverCubit()),
    BlocProvider(create: (context) => UpdateDriverParameterCubit()),
    BlocProvider(create: (context) => UpdateAddEditVehicleIdCubit()),
    BlocProvider(create: (context) => LocationCubit()),
    BlocProvider(create: (context) => MarkerCubit()),

    BlocProvider(create: (context) => RideStatusCubit()),
    BlocProvider(create: (context) => UpdateRideRequestCubit()),
    BlocProvider(create: (context) => GetDriverDataCubit()),
    BlocProvider(create: (context) => SetupStepCubit(initialStep: 0)),
    BlocProvider(create: (context) => UserDataCubit()),
    BlocProvider(create: (context) => AddDriverCubit()),
    BlocProvider(create: (context) => SetDocImage()),
    BlocProvider(create: (context) => SetVehicleImage()),
    BlocProvider(create: (context) => SetInsuranceImage()),
    BlocProvider(
        create: (context) =>
            BookRideConfirmOtpCubit(RegisterVehicleRepository())),
    BlocProvider(create: (context) => MyImageCubit()),
    BlocProvider(create: (context) => NameCubit()),
    BlocProvider(create: (context) => PhoneCubit()),
    BlocProvider(create: (context) => EmailCubit()),
    BlocProvider(create: (context) => GenderCubit()),
    BlocProvider(create: (context) => BottomBarCubit()),
    BlocProvider(create: (context) => UpdateProfileCubit(ProfileRepository())),
    BlocProvider(create: (context) => SosCubit(ProfileRepository())),
    BlocProvider(create: (context) => DeleteAccountCubit(ProfileRepository())),
    BlocProvider(create: (context) => HistoryCubit(HistoryRepository())),
    BlocProvider(create: (context) => ChangeEmailCubits(AuthRepository())),
    BlocProvider(create: (context) => ChangePhoneCubits(AuthRepository())),
    BlocProvider(create: (context) => EmailOtpCubit(AuthRepository())),
    BlocProvider(
        create: (context) =>
            UpdateRideStatusInDatabaseCubit(RealtimeRepository())),
    BlocProvider(create: (context) => PaymentCubit()),
    BlocProvider(
        create: (context) =>
            UpdatePaymentStatusByDriverCubit(PaymentRepository())),
    BlocProvider(create: (context) => EarningCubit(PaymentRepository())),
    BlocProvider(create: (context) => WalletDataCubit(PaymentRepository())),
    BlocProvider(
        create: (context) => WalletTransactionsCubit(PaymentRepository())),
    BlocProvider(
        create: (context) => PayoutTransactionCubit(PaymentRepository())),
    BlocProvider(
        create: (context) => PaymentMethodCubits(PaymentRepository())),
    BlocProvider(create: (context) => AmountPayoutCubit(PaymentRepository())),
    BlocProvider(create: (context) => GetDocApprovalStatusCubit()),
    BlocProvider(create: (context) => GetDriverStatusCubit()),
    BlocProvider(create: (context) => UpdateBookingIdCubit()),
    BlocProvider(create: (context) => ReviewCubit(ReviewRepository())),
    BlocProvider(create: (context) => DocumentApprovedStatusCubit()),
    BlocProvider(create: (context) => GetPolylineCubit()),
    BlocProvider(create: (context) => UpdateRideMarkerCubit()),
    BlocProvider(create: (context) => RideLocationCubit()),
    BlocProvider(create: (context) => GetListenRideRequestBookingIdCubit()),
    BlocProvider(create: (context) => DashboardCubit(DashboradRepository())),
    BlocProvider(create: (context) => RideMarkerCubit()),
    BlocProvider(create: (context) => HomeMarkerCubit()),
    BlocProvider(create: (context) => GeneralCubit(ProfileRepository())),
    BlocProvider(create: (context) => StaticPageCubits(ProfileRepository())),
     BlocProvider(create: (context) => GetRideDataCubit()),
    BlocProvider(create: (context) => GetRideRequestStatusCubit()),
    BlocProvider(create: (context) => GetPaymentStatusAndMethodCubit()),
    BlocProvider(create: (context) => GetPaymentAmountCubit()),
    BlocProvider(create: (context) => FirebaseUpdateIntervalCubit()),
    BlocProvider(create: (context) => BackgroundLocationIntervalCubit()),
    BlocProvider(create: (context) => DriverSearchIntervalCubit()),
    BlocProvider(create: (context) => MinimumNegativeCubit()),
    BlocProvider(create: (context) => DriverFoodCubit(FoodDeliveryRepository())),
  ];
}
