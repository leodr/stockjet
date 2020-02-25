import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_design/simple_design.dart';
import 'package:stockjet/custom_pages/company_page.dart';
import 'package:stockjet/data_controller.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List searchList = [];

  List companies;

  List favorites = [];

  bool isLoaded = false;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    getCompanies();
    getSP();
    super.initState();
  }

  Future getSP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites = prefs.getStringList("favs") == null
          ? []
          : prefs.getStringList("favs");
    });
  }

  void getCompanies() async {
    companies = await storage.getCompanies();
    setState(() {
      searchList = _fetchList("");
      isLoaded = true;
    });
  }

  void editSP(String symbol) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var list = prefs.getStringList("favs") ?? [];
    if (list.contains(symbol)) {
      prefs.setStringList("favs", list..remove(symbol));
    } else {
      prefs.setStringList("favs", list..add(symbol));
    }
    getSP();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CustomScrollView(
      slivers: <Widget>[
        SDSliverAppBar(
          pinned: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: TextField(
            autofocus: true,
            controller: searchController,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Search",
            ),
            onChanged: (criteria) {
              setState(() {
                searchList = _fetchList(criteria);
              });
            },
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.clear,
              ),
              onPressed: () {
                searchController.clear();
                setState(() {
                  searchList = _fetchList("");
                });
              },
            )
          ],
        ),
        isLoaded
            ? SliverList(
                delegate: SliverChildBuilderDelegate(
                    (context, index) => ListTile(
                          title:
                              Text(searchList[index]["symbol"].toUpperCase()),
                          subtitle: Text(searchList[index]["name"]),
                          trailing: IconButton(
                            icon: Icon(
                                favorites.contains(searchList[index]["symbol"])
                                    ? Icons.star
                                    : Icons.star_border),
                            onPressed: () =>
                                editSP(searchList[index]["symbol"]),
                          ),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    CompanyPage(searchList[index]["symbol"])));
                          },
                        ),
                    childCount: searchList.length),
              )
            : SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
      ],
    ));
  }

  List _fetchList(String criteria) {
    List result = [];

    for (int i = 0; i < companies.length; i++) {
      if (companies[i]["symbol"]
              .toString()
              .toLowerCase()
              .trim()
              .contains(criteria.toLowerCase().trim()) ||
          companies[i]["name"]
              .toString()
              .toLowerCase()
              .trim()
              .contains(criteria.toLowerCase().trim())) {
        result.add(companies[i]);
      }
    }

    print(result);

    return result;
  }
}
