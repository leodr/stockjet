import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DataController {
  Map data = {};

  List companies = [];

  Future<List> getCompanies() async {
    if (companies.length > 1) {
      return companies;
    } else {
      final http.Response response =
          await http.get('https://api.iextrading.com/1.0/ref-data/symbols');
      companies = json.decode(response.body) as List;

      return companies;
    }
  }

  Future<String> get(
      {@required String symbol,
      Attributes attribute,
      bool refresh = false}) async {
    if (attribute == null) {
      return data[symbol].toString();
    }

    String request;

    try {
      request = (data[symbol] != null
          ? data[symbol][attribute.toString().split('.')[1]]
          : null) as String;
    } catch (e) {
      request = null;
    }

    if (request == null || request == '' || refresh) {
      String url = '';

      switch (attribute) {
        case Attributes.news:
          url = 'https://api.iextrading.com/1.0/stock/$symbol/news/last/10';
          break;
        case Attributes.shortNews:
          url = 'https://api.iextrading.com/1.0/stock/$symbol/news/last/2';
          break;
        case Attributes.company:
          url = 'https://api.iextrading.com/1.0/stock/$symbol/company';
          break;
        case Attributes.quote:
          url = 'https://api.iextrading.com/1.0/stock/$symbol/quote';
          break;
        case Attributes.stats:
          url = 'https://api.iextrading.com/1.0/stock/$symbol/stats';
          break;
        case Attributes.logoUrl:
          url = 'https://api.iextrading.com/1.0/stock/$symbol/logo';
          break;
        case Attributes.chart5y:
          url = 'https://api.iextrading.com/1.0/stock/$symbol/chart/5y';
          break;
        case Attributes.chart2y:
          url = 'https://api.iextrading.com/1.0/stock/$symbol/chart/2y';
          break;
        case Attributes.chart1y:
          url = 'https://api.iextrading.com/1.0/stock/$symbol/chart/1y';
          break;
        case Attributes.chart6m:
          url = 'https://api.iextrading.com/1.0/stock/$symbol/chart/6m';
          break;
        case Attributes.chart3m:
          url = 'https://api.iextrading.com/1.0/stock/$symbol/chart/3m';
          break;
        case Attributes.chart1m:
          url = 'https://api.iextrading.com/1.0/stock/$symbol/chart/1m';
          break;
        case Attributes.chart1d:
          url = 'https://api.iextrading.com/1.0/stock/$symbol/chart/1d';
          break;
      }

      final http.Response response = await http.get(url);

      if (data.containsKey(symbol)) {
        data[symbol]
            .addAll({attribute.toString().split('.')[1]: response.body});
      } else {
        data.addAll({
          symbol: {attribute.toString().split('.')[1]: response.body}
        });
      }
      return response.body;
    } else {
      return request;
    }
  }
}

enum Attributes {
  news,
  shortNews,
  company,
  stats,
  quote,
  logoUrl,
  chart5y,
  chart2y,
  chart1y,
  chart6m,
  chart3m,
  chart1m,
  chart1d
}

final DataController storage = DataController();
