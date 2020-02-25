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

  List<String> favorites = <String>[];

  bool isLoaded = false;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    getCompanies();
    getSP();
    super.initState();
  }

  Future<void> getSP() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites = prefs.getStringList('favs') ?? <String>[];
    });
  }

  Future<void> getCompanies() async {
    companies = await storage.getCompanies();
    setState(() {
      searchList = _fetchList('');
      isLoaded = true;
    });
  }

  Future<void> editSP(String symbol) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList('favs') ?? <String>[];
    if (list.contains(symbol)) {
      prefs.setStringList('favs', list..remove(symbol));
    } else {
      prefs.setStringList('favs', list..add(symbol));
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
                hintText: 'Search',
              ),
              onChanged: (String criteria) {
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
                    searchList = _fetchList('');
                  });
                },
              )
            ],
          ),
          if (isLoaded)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) => ListTile(
                        title: Text(searchList[index]['symbol'].toUpperCase()),
                        subtitle: Text(searchList[index]['name']),
                        trailing: IconButton(
                          icon: Icon(
                              favorites.contains(searchList[index]['symbol'])
                                  ? Icons.star
                                  : Icons.star_border),
                          onPressed: () => editSP(searchList[index]['symbol']),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) => CompanyPage(
                                searchList[index]["symbol"],
                              ),
                            ),
                          );
                        },
                      ),
                  childCount: searchList.length),
            )
          else
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
        ],
      ),
    );
  }

  List _fetchList(String criteria) {
    List result = [];

    for (int i = 0; i < companies.length; i++) {
      if (companies[i]['symbol']
              .toString()
              .toLowerCase()
              .trim()
              .contains(criteria.toLowerCase().trim()) ||
          companies[i]['name']
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
