import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pixez/bloc/controller_bloc.dart';
import 'package:pixez/bloc/controller_state.dart';
import 'package:pixez/component/illust_card.dart';
import 'package:pixez/page/hello/new/illust/bloc/bloc.dart';

class NewIllustPage extends StatefulWidget {
  final String restrict;

  const NewIllustPage({Key key, this.restrict = "public"}) : super(key: key);

  @override
  _NewIllustPageState createState() => _NewIllustPageState();
}

class _NewIllustPageState extends State<NewIllustPage> {
  Completer<void> _refreshCompleter, _loadCompleter;
  EasyRefreshController _easyRefreshController;
  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _refreshCompleter = Completer<void>();
    _loadCompleter = Completer<void>();
    _easyRefreshController = EasyRefreshController();
    // BlocProvider.of<NewIllustBloc>(context)
    //     .add(FetchIllustEvent(widget.restrict));
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _easyRefreshController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<NewIllustBloc, NewIllustState>(
          listener: (context, state) {
            if (state is DataNewIllustState) {
              _loadCompleter?.complete();
              _loadCompleter = Completer();
              _refreshCompleter?.complete();
              _refreshCompleter = Completer();
            }
            if (state is FailIllustState) {
              _easyRefreshController.finishRefresh(
                success: false,
              );
              _refreshCompleter?.complete();
              _refreshCompleter = Completer();
            }
          },
        ),
        BlocListener<ControllerBloc, ControllerState>(
          listener: (BuildContext context, ControllerState state) {
            if (state is ScrollToTopState) {
              if (state.name == 'dymanic') _scrollController?.jumpTo(0.0);
            }
          },
        )
      ],
      child: BlocBuilder<NewIllustBloc, NewIllustState>(condition: (pre, now) {
        return now is! FailIllustState;
      }, builder: (context, state) {
        return EasyRefresh(
          controller: _easyRefreshController,
          firstRefresh: true,
          child: state is DataNewIllustState
              ? StaggeredGridView.countBuilder(
                  crossAxisCount: 2,
                  controller: _scrollController,
                  itemCount: state.illusts.length,
                  itemBuilder: (context, index) {
                    return IllustCard(state.illusts[index]);
                  },
                  staggeredTileBuilder: (int index) => StaggeredTile.fit(1),
                )
              : Container(),
          onRefresh: () async {
            BlocProvider.of<NewIllustBloc>(context)
                .add(FetchIllustEvent(widget.restrict));
            return _refreshCompleter.future;
          },
          onLoad: () async {
            if (state is DataNewIllustState)
              BlocProvider.of<NewIllustBloc>(context)
                  .add(LoadMoreEvent(state.nextUrl, state.illusts));
            return _loadCompleter.future;
          },
        );
      }),
    );
  }
}
