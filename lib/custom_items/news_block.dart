import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stockjet/custom_items/news_item.dart';
import 'package:stockjet/data_controller.dart';

class NewsBlock extends StatefulWidget {
  final int newsCount;
  final String stockKey;

  NewsBlock({this.newsCount: 2, @required this.stockKey});

  @override
  NewsBlockState createState() {
    return new NewsBlockState();
  }
}

class NewsBlockState extends State<NewsBlock> {
  List<Widget> newsList = [
    SizedBox(height: 100.0, child: Center(child: CircularProgressIndicator()))
  ];

  @override
  void initState() {
    getNews();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Flex(
      children: newsList,
      direction: Axis.vertical,
    );
  }

  Future getNews() async {
    List<Widget> newsItemList = [];

    var response = await storage.get(
        symbol: widget.stockKey, attribute: Attributes.shortNews);
    List news = json.decode(response);

    for (int i = 0; i < news.length; i++) {
      newsItemList.add(NewsItem(
        news[i],
      ));
    }

    setState(() {
      newsList = newsItemList;
    });
  }
}
