import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:pixez/er/sharer.dart';
import 'package:pixez/models/export_tag_history_data.dart';
import 'package:pixez/saf_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'book_tag_store.g.dart';

class BookTagStore = _BookTagStoreBase with _$BookTagStore;

abstract class _BookTagStoreBase with Store {
  static const BOOK_TAG_LIST = 'book_tag_list';
  @observable
  ObservableList<String> bookTagList = ObservableList();
  SharedPreferences? pre;

  @action
  init() async {
    try {
      pre = await SharedPreferences.getInstance();
      final bookList = pre!.getStringList(BOOK_TAG_LIST) ?? [];
      bookTagList.clear();
      bookTagList.addAll(bookList);
    } catch (e) {}
  }

  @action
  Future<void> bookTag(String tag) async {
    if (bookTagList.contains(tag)) return;
    await pre!.setStringList(BOOK_TAG_LIST, bookTagList..add(tag));
  }

  @action
  Future<void> unBookTag(String tag) async {
    await pre!.setStringList(BOOK_TAG_LIST, bookTagList..remove(tag));
  }

  @action
  Future<void> adjustBookTag(List<String> list) async {
    await pre!.setStringList(BOOK_TAG_LIST, list);
  }

  @action
  reset() async {
    await pre!.remove(BOOK_TAG_LIST);
    bookTagList.clear();
  }

  final EXPORT_TYPE = "book_tags";

  Future<void> importData() async {
    final result = await SAFPlugin.openFile();
    if (result == null) return;
    final json = utf8.decode(result);
    final decoder = JsonDecoder();
    final map = decoder.convert(json);
    final data = ExportData.fromJson(map);
    if (data.bookTags == null) return;
    final bookList = pre!.getStringList(BOOK_TAG_LIST) ?? [];
    bookList.removeWhere((element) => data.bookTags!.contains(element));
    bookList.addAll(data.bookTags!);
    await pre!.setStringList(BOOK_TAG_LIST, bookList);
    await init();
  }

  Future<void> exportData(BuildContext context) async {
    final exportData = ExportData(bookTags: bookTagList.toList());
    final uint8List = utf8.encode(jsonEncode(exportData));
    if (Platform.isIOS) {
      await Sharer.exportUint8List(context, uint8List, '${EXPORT_TYPE}.json');
    } else {
      final uriStr =
          await SAFPlugin.createFile("${EXPORT_TYPE}.json", "application/json");
      if (uriStr == null) return;
      await SAFPlugin.writeUri(uriStr, uint8List);
    }
  }
}
