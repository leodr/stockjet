import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_design/simple_design.dart';
import 'package:stockjet/custom_items/list_item.dart';
import 'package:stockjet/custom_items/news_block.dart';
import 'package:stockjet/custom_items/news_item.dart';
import 'package:stockjet/custom_items/stocks_item.dart';
import 'package:stockjet/custom_pages/company_page.dart';
import 'package:stockjet/custom_pages/search_page.dart';
import 'package:stockjet/data_controller.dart';

void main() {
  runApp(MyApp());
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: const Color(0xFF37474F),
      systemNavigationBarDividerColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
}

class MyApp extends StatelessWidget {
  final ThemeData themeData = SimpleDesign.lightTheme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: themeData.scaffoldBackgroundColor,
      title: 'Stoxer',
      theme: themeData,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  List<Widget> stocksList = [
    SizedBox(
        height: 700.0,
        child: Center(
          child: CircularProgressIndicator(),
        ))
  ];

  List newsList = [];

  List<String> companies = [];

  List<String> favoriteList = [];

  final String newsUrl =
      "https://api.iextrading.com/1.0/stock/market/news/last/20";

  int index = 0;

  AnimationController searchBarAnimationController;

  AnimationController pageTransitionController;

  ScrollController firstPageScroller = ScrollController(),
      secondPageScroller = ScrollController(),
      thirdPageScroller = ScrollController();

  @override
  void initState() {
    pageTransitionController = AnimationController(vsync: this);

    getStocksData();
    getNewsData();
    getCompanies();
    getFavorites();
    super.initState();
  }

  Widget _buildHomePage() => RefreshIndicator(
        key: Key("home"),
        displacement: kToolbarHeight,
        onRefresh: () async {
          return await getStocksData();
        },
        child: CustomScrollView(
          controller: firstPageScroller,
          slivers: <Widget>[
            SDSliverAppBar(
              pinned: true,
              actions: <Widget>[_buildSearchButton()],
              title: RichText(
                  text: TextSpan(
                      text: "Stoxer ",
                      style: Theme.of(context).textTheme.headline6,
                      children: [
                    TextSpan(
                        text: "Home",
                        style: Theme.of(context)
                            .textTheme
                            .headline6
                            .copyWith(fontWeight: FontWeight.normal))
                  ])),
            ),
            SliverList(delegate: SliverChildListDelegate(stocksList))
          ],
        ),
      );

  Widget _buildNewsPage() => RefreshIndicator(
        key: Key("news"),
        displacement: kToolbarHeight,
        onRefresh: () async {
          return await getNewsData();
        },
        child: CustomScrollView(
          controller: secondPageScroller,
          slivers: <Widget>[
            SDSliverAppBar(
              title: RichText(
                  text: TextSpan(
                      text: "Stoxer ",
                      style: Theme.of(context).textTheme.headline6,
                      children: [
                    TextSpan(
                        text: "News",
                        style: Theme.of(context)
                            .textTheme
                            .headline6
                            .copyWith(fontWeight: FontWeight.normal))
                  ])),
              pinned: true,
              actions: <Widget>[_buildSearchButton()],
            ),
            SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
              return NewsItem(
                newsList[index],
                divider: index != 0,
              );
            }, childCount: newsList.length))
          ],
        ),
      );

  Widget _buildFavoritesPage() => RefreshIndicator(
        key: Key("favorite"),
        onRefresh: () async {
          return await getFavorites();
        },
        child: CustomScrollView(
          controller: thirdPageScroller,
          slivers: <Widget>[
            SDSliverAppBar(
              pinned: true,
              title: RichText(
                  text: TextSpan(
                      text: "Stoxer ",
                      style: Theme.of(context).textTheme.headline6,
                      children: [
                    TextSpan(
                        text: "Favorites",
                        style: Theme.of(context)
                            .textTheme
                            .headline6
                            .copyWith(fontWeight: FontWeight.normal))
                  ])),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    getFavorites();
                  },
                ),
                _buildSearchButton()
              ],
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Dismissible(
                  direction: DismissDirection.startToEnd,
                  onDismissed: (direction) {
                    updatePrefs(favoriteList[index]);
                  },
                  background: Container(
                    color: Theme.of(context).errorColor,
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.clear)),
                  ),
                  key: Key(favoriteList[index]),
                  child: ExpansionTile(
                    key: Key(favoriteList[index]),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                getName(favoriteList[index]),
                                style: Theme.of(context).textTheme.bodyText2,
                              ),
                              SizedBox(height: 2.0),
                              Text(
                                favoriteList[index],
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.launch,
                            color: IconTheme.of(context).color,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    CompanyPage(favoriteList[index])));
                          },
                        ),
                      ],
                    ),
                    children: <Widget>[
                      StocksItem(stockKey: favoriteList[index]),
                      NewsBlock(stockKey: favoriteList[index])
                    ],
                  ),
                );
              }, childCount: favoriteList == null ? 0 : favoriteList.length),
            )
          ],
        ),
      );

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildNewsPage();
      case 2:
        return _buildFavoritesPage();
    }

    return Text("Error");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: _getBody(index),
      ),
      bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          onTap: (position) async {
            if (position != index) {
              setState(() {
                index = position;
              });
            } else {
              switch (index) {
                case 0:
                  firstPageScroller.animateTo(0.0,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                  break;
                case 1:
                  secondPageScroller.animateTo(0.0,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                  break;
                case 2:
                  thirdPageScroller.animateTo(0.0,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                  break;
              }
            }
          },
          currentIndex: index,
          items: [
            BottomNavigationBarItem(
                title: Text("Home"),
                icon: Icon(MdiIcons.homeVariantOutline),
                activeIcon: Icon(MdiIcons.homeVariant)),
            BottomNavigationBarItem(
                title: Text("News"), icon: Icon(MdiIcons.newspaper)),
            BottomNavigationBarItem(
                title: Text("Favorites"),
                icon: Icon(Icons.star_border),
                activeIcon: Icon(Icons.star)),
          ]),
    );
  }

  Future<Null> getStocksData() async {
    List<Widget> list = [];

    var response = await http
        .get("https://api.iextrading.com/1.0/stock/market/list/gainers");
    var winners = json.decode(response.body);

    list.add(SDSectionHeader("Winners"));

    list.add(SizedBox(
      height: 50.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => Row(
          children: <Widget>[
            CustomListItem(winners[index]),
            Container(
              width: 1.0,
              height: 25.0,
              color: index < winners.length - 1
                  ? Theme.of(context).dividerColor
                  : Colors.transparent,
            )
          ],
        ),
        itemCount: winners.length,
      ),
    ));

    response = await http
        .get("https://api.iextrading.com/1.0/stock/market/list/losers");
    var losers = json.decode(response.body);

    list.add(SDSectionHeader("Losers"));

    list.add(SizedBox(
      height: 50.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => Row(
          children: <Widget>[
            CustomListItem(losers[index]),
            Container(
              width: 1.0,
              height: 25.0,
              color: index < losers.length - 1
                  ? Theme.of(context).dividerColor
                  : Colors.transparent,
            )
          ],
        ),
        itemCount: losers.length,
      ),
    ));

    list.add(SizedBox(height: 20.0));

    List<String> favs = await getFavs();
    if (favs != null) {
      for (int i = 0; i < favs.length; i++) {
        list.add(
          StocksItem(
            stockKey: favs[i].toString(),
          ),
        );
      }
    } else {
      list.add(SizedBox(
        height: 200.0,
        child: Center(
            child: Container(
          child: OutlineButton(
            color: Theme.of(context).scaffoldBackgroundColor,
            highlightedBorderColor: Theme.of(context).accentColor,
            highlightColor: Colors.transparent,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) => SearchPage())),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add),
              SizedBox(width: 8.0),
              Text("ADD FAVORITES",
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            ]),
          ),
        )),
      ));
    }

    setState(() {
      stocksList = list;
    });

    return null;
  }

  Future<Null> getNewsData() async {
    var response = await http.get(newsUrl);
    List jsonCode = json.decode(response.body);

    setState(() {
      newsList = jsonCode;
    });

    return null;
  }

  Future getCompanies() async {
    return storage.getCompanies();
  }

  String getName(String stockKey) {
    for (int i = 0; i < companies.length; i++) {
      if (companies[i].split(", ")[0] == stockKey) {
        return companies[i].split(", ")[1];
      }
    }

    return "";
  }

  Future<List<String>> getFavs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> favs = prefs.getStringList("favs");

    print(favs);

    if (favs != null) {
      if (favs.length > 0) {
        return favs;
      }
    }

    return null;
  }

  Future<Null> getFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      favoriteList = prefs.getStringList("favs");
    });

    return null;
  }

  void updatePrefs(String companyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList("favs");
    if (favs != null) {
      if (favs.indexOf(companyId) == -1) {
        favs.add(companyId);
      } else {
        favs.remove(companyId);
      }
    } else {
      favs = [companyId];
    }

    prefs.setStringList("favs", favs);
  }

  Widget _buildSearchButton() => IconButton(
        icon: Icon(Icons.search),
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (BuildContext context) => SearchPage())),
      );
}

class CircleClipper extends CustomClipper<Rect> {
  double radius;

  CircleClipper(this.radius);

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => true;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      size.width - kToolbarHeight / 2 - radius,
      kToolbarHeight / 2 - radius,
      size.width - kToolbarHeight / 2 + radius,
      kToolbarHeight / 2 + radius,
    );
  }
}
