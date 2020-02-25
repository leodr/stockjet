import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stockjet/custom_items/time_series_chart.dart';
import 'package:stockjet/custom_pages/company_page.dart';
import 'package:stockjet/data_controller.dart';

class StocksItem extends StatefulWidget {
  const StocksItem({@required this.stockKey});

  final String stockKey;

  @override
  StocksItemState createState() {
    return StocksItemState();
  }
}

class StocksItemState extends State<StocksItem> {
  Widget chart = const Center(
    child: CircularProgressIndicator(),
  );

  double change = 0.0;

  @override
  void initState() {
    getChartData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => CompanyPage(widget.stockKey),
          ),
        );
      },
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Text(
              widget.stockKey.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.0),
            ),
          ),
          SizedBox(width: 150.0, height: 65.0, child: chart),
        ],
      ),
      trailing: Text(
        (change >= 0 ? '+' + change.toString() : change.toString()) + '%',
        style: Theme.of(context).textTheme.bodyText1.copyWith(
              color: change >= 0 ? Colors.green : Theme.of(context).errorColor,
            ),
      ),
    );
  }

  Future<void> getChartData() async {
    String response = await storage.get(
        symbol: widget.stockKey, attribute: Attributes.chart1d);

    if (response.length <= 200) {
      response = await storage.get(
          symbol: widget.stockKey, attribute: Attributes.chart1m);
    }
    final List code = json.decode(response) as List;

    final List<TimeSeriesSales> data = <TimeSeriesSales>[];

    for (int i = 0; i < code.length; i++) {
      try {
        data.add(TimeSeriesSales(
            DateTime(
              int.parse(code[i]['date'].split('-')[0]),
              int.parse(code[i]['date'].split('-')[1]),
              int.parse(code[i]['date'].split('-')[2]),
            ),
            double.parse(code[i]['close'].toString())));
      } catch (e) {
        if (code[i]['average'] > 0) {
          data.add(TimeSeriesSales(
              DateTime(
                  int.parse(code[i]['date'].substring(0, 4)),
                  int.parse(code[i]['date'].substring(4, 6)),
                  int.parse(code[i]['date'].substring(6, 8)),
                  int.parse(code[i]['minute'].split(':')[0]),
                  int.parse(code[i]['minute'].split(':')[1])),
              double.parse(code[i]['average'].toString())));
        }
      }
    }

    print(widget.stockKey + ":" + code.toString());

    setState(
      () {
        chart = TimeSeriesChart.fromData(
          data,
          interactive: false,
          animate: false,
        );
        try {
          change = double.parse(
              ((code[code.length - 1]['close'] - code[0]['close']) /
                      code[0]['close'] *
                      100)
                  .toStringAsFixed(3));
        } catch (e) {
          int counter = 1;
          while (code[code.length - counter] <= 0 || counter >= code.length) {
            counter++;
          }
          change = double.parse(
            ((code[code.length - counter]['average'] - code[0]['average']) /
                    code[0]['average'] *
                    100)
                .toStringAsFixed(3),
          );
        }
      },
    );
  }
}
