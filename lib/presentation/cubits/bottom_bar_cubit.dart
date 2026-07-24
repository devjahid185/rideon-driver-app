import 'package:flutter_bloc/flutter_bloc.dart';




class BottomBarChangeState  {
  final int index;
  BottomBarChangeState(this.index);
}

class BottomBarCubit extends Cubit<BottomBarChangeState>{
  BottomBarCubit():super(BottomBarChangeState(0));
  void changeTabIndex(int index){
    emit(BottomBarChangeState(index));
  }
}