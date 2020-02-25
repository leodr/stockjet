import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_design/simple_design.dart';
import 'package:stockjet/custom_items/news_item.dart';
import 'package:stockjet/custom_items/time_series_chart.dart';
import 'package:stockjet/data_controller.dart';

class CompanyPage extends StatefulWidget {
  final String companyId;

  CompanyPage(this.companyId);

  final List<String> timeIntervals = ["5y", "2y", "1y", "6m", "3m", "1m", "1d"];

  @override
  _CompanyPageState createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage>
    with SingleTickerProviderStateMixin {
  String stockKey = "Company";

  List<Widget> companyInfos = [];

  Widget graph = Container();

  IconData topRightIcon;

  String url;

  Widget chart = Center(
    child: CircularProgressIndicator(),
  );

  List<DropdownMenuItem> dropDownItems = [];

  List<Widget> tableRows = [];

  String value;

  String title = "\$";

  int counter = 1;

  TabController controller;

  List<Widget> newsList = [
    SizedBox(
      height: 400.0,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    )
  ];

  @override
  void initState() {
    getCompanyData(widget.companyId);

    controller = TabController(
        vsync: this, length: widget.timeIntervals.length, initialIndex: 2);

    url =
        "https://api.iextrading.com/1.0/stock/" + widget.companyId + "/chart/";

    widget.timeIntervals.forEach((item) {
      dropDownItems.add(DropdownMenuItem(
        child: Text(item),
        value: item,
      ));
    });

    value = widget.timeIntervals[2];

    getChartData(value);

    getData();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 3,
      length: widget.timeIntervals.length,
      child: Scaffold(
        backgroundColor: Color.lerp(
            Theme.of(context).scaffoldBackgroundColor, Colors.white, 0.1),
        floatingActionButton: FloatingActionButton(
          onPressed: () => updatePrefs(stockKey),
          child: Icon(topRightIcon),
        ),
        body: RefreshIndicator(
            displacement: kToolbarHeight,
            onRefresh: () async {
              await getChartData(value);
              await getCompanyData(widget.companyId);
              return await getData();
            },
            child: CustomScrollView(
              slivers: <Widget>[
                SDSliverAppBar(
                  title: Text(
                    stockKey,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  pinned: true,
                ),
                SliverList(
                    delegate: SliverChildListDelegate(
                  [
                    Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: Text(
                                title,
                                style: TextStyle(fontSize: 40.0),
                              ),
                            ),
                          ),
                          SizedBox(height: 280.0, child: chart),
                          Stack(
                            children: <Widget>[
                              IgnorePointer(
                                child: TabBar(
                                  indicatorPadding: EdgeInsets.all(0.0),
                                  controller: controller,
                                  tabs: List.generate(
                                      widget.timeIntervals.length,
                                      (index) => Tab(
                                            child: Container(),
                                          )),
                                ),
                              ),
                            ]..add(Row(
                                children: List.generate(
                                    widget.timeIntervals.length,
                                    (index) => Expanded(
                                          child: FlatButton(
                                              onPressed: () {
                                                setState(() {
                                                  value = widget
                                                      .timeIntervals[index];
                                                  controller.animateTo(index);
                                                });
                                                getChartData(widget
                                                    .timeIntervals[index]);
                                              },
                                              child: SizedBox(
                                                height: 46.0,
                                                child: Center(
                                                  child: Text(widget
                                                      .timeIntervals[index]
                                                      .toUpperCase()),
                                                ),
                                              )),
                                        )),
                              )),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0)
                  ]
                    ..addAll(newsList)
                    ..addAll(companyInfos)
                    ..add(Column(
                      mainAxisSize: MainAxisSize.min,
                      children: tableRows,
                    )),
                ))
              ],
            )),
      ),
    );
  }

  Future<Null> getCompanyData(String companyId) async {
    List<Widget> list = [];

    var response =
        await storage.get(symbol: companyId, attribute: Attributes.company);
    var jsonCode = json.decode(response);

    var imgJSON =
        await storage.get(symbol: companyId, attribute: Attributes.logoUrl);
    String imgUrl = json.decode(imgJSON)["url"];

    list.add(Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Flex(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                imgUrl != null
                    ? Card(
                        child: CachedNetworkImage(
                          imageUrl: imgUrl,
                          fit: BoxFit.contain,
                          errorWidget: (context, _, __) => Container(
                              width: 100.0,
                              height: 100.0,
                              child: Center(child: Icon(Icons.clear))),
                          placeholder: (context, _) => Container(
                            width: 100.0,
                            height: 100.0,
                            child: CircularProgressIndicator(),
                          ),
                          width: 100.0,
                          height: 100.0,
                        ),
                      )
                    : Container(),
                SizedBox(width: 4.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              jsonCode["companyName"],
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                  fontSize: 20.0, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.language),
                            onPressed: () {
                              _launchURL(context, jsonCode["website"]);
                            },
                          )
                        ],
                      ),
                      Text(
                        jsonCode["sector"] + ", " + jsonCode["industry"],
                        style: TextStyle(fontSize: 18.0),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(jsonCode["description"],
                  style: TextStyle(fontSize: 16.0)),
            ),
          ],
          direction: Axis.vertical,
        ),
      ),
    ));

    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      if (prefs.getStringList("favs") != null) {
        if (prefs.getStringList("favs").indexOf(widget.companyId) >= 0) {
          topRightIcon = Icons.bookmark;
        } else {
          topRightIcon = Icons.bookmark_border;
        }
      } else {
        topRightIcon = Icons.bookmark_border;
      }
      companyInfos = list;
      stockKey = jsonCode["symbol"];
    });

    List<Widget> newsItemList = [];

    response = await storage.get(symbol: companyId, attribute: Attributes.news);
    List news = json.decode(response);

    for (int i = 0; i < news.length; i++) {
      newsItemList.add(NewsItem(
        news[i],
        divider: i != 0,
      ));
    }

    setState(() {
      newsList = [
        SizedBox(height: 8.0),
        Flex(
          direction: Axis.vertical,
          children: newsItemList,
        )
      ];
    });

    return null;
  }

  void _launchURL(BuildContext context, String url) async {
    try {
      await launch(
        url,
        option: CustomTabsOption(
            toolbarColor: Theme.of(context).primaryColor,
            enableDefaultShare: true,
            enableUrlBarHiding: true,
            showPageTitle: true,
            animation: CustomTabsAnimation.slideIn()),
      );
    } catch (e) {
      // An exception is thrown if browser app is not installed on Android device.
      debugPrint(e.toString());
    }
  }

  void updatePrefs(String companyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList("favs");
    if (favs == null) {
      favs = [];
    }
    if (favs.indexOf(companyId) == -1) {
      favs.add(companyId);
      setState(() {
        topRightIcon = Icons.bookmark;
      });
    } else {
      favs.remove(companyId);
      setState(() {
        topRightIcon = Icons.bookmark_border;
      });
    }

    prefs.setStringList("favs", favs);
  }

  Future<Null> getData() async {
    var response = await storage.get(
        symbol: widget.companyId, attribute: Attributes.stats);
    var stats = json.decode(response);

    response = await storage.get(
        symbol: widget.companyId, attribute: Attributes.quote);
    var quote = json.decode(response);

    final List<Widget> data = [];

    data.addAll([
      getTableRow("Last Close", quote["previousClose"].toString()),
      getTableRow("Open", quote["open"].toString()),
      getTableRow("Low", quote["low"].toString()),
      getTableRow("High", quote["high"].toString()),
      getTableRow("52W High", stats["week52high"].toString()),
      getTableRow("52W Low", stats["week52low"].toString()),
      getTableRow("Market Cap", stats["marketcap"].toString()),
      getTableRow("Volume", quote["avgTotalVolume"].toString()),
      getTableRow("Beta", stats["beta"].toString()),
      getTableRow("Latest EPS", stats["latestEPS"].toString()),
      getTableRow("Latest EPS Date", stats["latestEPSDate"].toString()),
      getTableRow("Float", stats["float"].toString()),
      getTableRow("Shared Outstanding", stats["sharesOutstanding"].toString()),
      getTableRow("Dividend", stats["dividendRate"].toString()),
      getTableRow("Yield", stats["dividendYield"].toString()),
      getTableRow("1 Year Change", stats["year1ChangePercent"].toString()),
    ]);

    setState(() {
      tableRows = data;
      title = "\$" + quote["latestPrice"].toString();
    });

    return null;
  }

  Future<Null> getChartData(String time) async {
    setState(() {
      chart = Center(child: CircularProgressIndicator());
    });

    Attributes attribute;

    switch (time) {
      case "5y":
        attribute = Attributes.chart5y;
        break;
      case "2y":
        attribute = Attributes.chart2y;
        break;
      case "1y":
        attribute = Attributes.chart1y;
        break;
      case "6m":
        attribute = Attributes.chart6m;
        break;
      case "3m":
        attribute = Attributes.chart3m;
        break;
      case "1m":
        attribute = Attributes.chart1m;
        break;
      case "1d":
        attribute = Attributes.chart1d;
        break;
    }

    var response =
        await storage.get(symbol: widget.companyId, attribute: attribute);
    var code = json.decode(response);

    final List<TimeSeriesSales> data = [];

    for (int i = 0; i < code.length; i++) {
      try {
        data.add(TimeSeriesSales(
            DateTime(
                int.parse(code[i]["date"].split("-")[0]),
                int.parse(code[i]["date"].split("-")[1]),
                int.parse(code[i]["date"].split("-")[2])),
            double.parse(code[i]["close"].toString())));
      } catch (e) {
        print(e);

        if (code[i]["average"] > 0) {
          data.add(TimeSeriesSales(
              DateTime(
                  int.parse(code[i]["date"].substring(0, 4)),
                  int.parse(code[i]["date"].substring(4, 6)),
                  int.parse(code[i]["date"].substring(6, 8)),
                  int.parse(code[i]["minute"].split(":")[0]),
                  int.parse(code[i]["minute"].split(":")[1])),
              double.parse(code[i]["average"].toString())));
        }
      }
    }

    setState(() {
      chart = TimeSeriesChart.fromData(
        data,
        interactive: true,
      );
    });

    return null;
  }

  Widget getTableRow(String statName, String value) {
    counter++;

    return Container(
        decoration: BoxDecoration(
            color: counter.isEven
                ? Theme.of(context).scaffoldBackgroundColor
                : Theme.of(context).cardColor),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                statName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                value,
                textAlign: TextAlign.end,
              ),
            )
          ],
        ));
  }
}
