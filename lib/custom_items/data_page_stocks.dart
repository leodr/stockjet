import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stockjet/custom_items/time_series_chart.dart';
import 'package:stockjet/data_controller.dart';

class DataPageStock extends StatefulWidget {
  final String stockKey;
  final bool onTap;
  final bool interactive;

  final List<String> timeIntervals = ["5y", "2y", "1y", "6m", "3m", "1m", "1d"];

  DataPageStock(
      {@required this.stockKey, this.onTap: true, this.interactive: false});

  @override
  StocksItemState createState() {
    return StocksItemState();
  }
}

class StocksItemState extends State<DataPageStock> {
  String url;

  Widget chart = Center(
    child: CircularProgressIndicator(),
  );

  List<DropdownMenuItem> dropDownItems = [];

  List<Widget> tableRows = [];

  String value;

  String title = "\$";

  int counter = 1;

  @override
  void initState() {
    url = "https://api.iextrading.com/1.0/stock/" + widget.stockKey + "/chart/";

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
    return RefreshIndicator(
      onRefresh: () async {
        await getChartData(value);
        return await getData();
      },
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(fontSize: 30.0),
                  ),
                  DropdownButton(
                    style: TextStyle(fontSize: 16.0),
                    onChanged: (item) {
                      setState(() {
                        value = item;
                      });
                      getChartData(item);
                    },
                    items: dropDownItems,
                    value: value,
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(height: 350.0, child: chart),
            ),
            SizedBox(height: 20.0)
          ]..add(Column(
              children: tableRows,
            ))),
    );
  }

  Future<Null> getData() async {
    var response =
        await storage.get(symbol: widget.stockKey, attribute: Attributes.stats);
    var stats = json.decode(response);

    response =
        await storage.get(symbol: widget.stockKey, attribute: Attributes.quote);
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
        await storage.get(symbol: widget.stockKey, attribute: attribute);
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
