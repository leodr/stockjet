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
      systemNavigationBarColor: Color(0xFF37474F),
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
  List<Widget> stocksList = <Widget>[
    const SizedBox(
        height: 700.0,
        child: Center(
          child: CircularProgressIndicator(),
        ))
  ];

  List newsList = [];

  List<String> companies = <String>[];

  List<String> favoriteList = <String>[];

  final String newsUrl =
      'https://api.iextrading.com/1.0/stock/market/news/last/20';

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
        key: const Key('home'),
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
                      text: 'Stoxer ',
                      style: Theme.of(context).textTheme.headline6,
                      children: <TextSpan>[
                    TextSpan(
                        text: 'Home',
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
        key: const Key('news'),
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
                      text: 'Stoxer ',
                      style: Theme.of(context).textTheme.headline6,
                      children: <TextSpan>[
                    TextSpan(
                        text: 'News',
                        style: Theme.of(context)
                            .textTheme
                            .headline6
                            .copyWith(fontWeight: FontWeight.normal))
                  ])),
              pinned: true,
              actions: <Widget>[_buildSearchButton()],
            ),
            SliverList(
                delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
              return NewsItem(
                newsList[index],
                divider: index != 0,
              );
            }, childCount: newsList.length))
          ],
        ),
      );

  Widget _buildFavoritesPage() => RefreshIndicator(
        key: const Key('favorite'),
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
                      text: 'Stoxer ',
                      style: Theme.of(context).textTheme.headline6,
                      children: <TextSpan>[
                    TextSpan(
                        text: 'Favorites',
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
              delegate:
                  SliverChildBuilderDelegate((BuildContext context, int index) {
                return Dismissible(
                  direction: DismissDirection.startToEnd,
                  onDismissed: (DismissDirection direction) {
                    updatePrefs(favoriteList[index]);
                  },
                  background: Container(
                    color: Theme.of(context).errorColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                              const SizedBox(height: 2.0),
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
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) => CompanyPage(
                                  favoriteList[index],
                                ),
                              ),
                            );
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

    return const Text('Error');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _getBody(index),
      ),
      bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          onTap: (int position) async {
            if (position != index) {
              setState(() {
                index = position;
              });
            } else {
              switch (index) {
                case 0:
                  firstPageScroller.animateTo(0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                  break;
                case 1:
                  secondPageScroller.animateTo(0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                  break;
                case 2:
                  thirdPageScroller.animateTo(0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                  break;
              }
            }
          },
          currentIndex: index,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                title: const Text('Home'),
                icon: Icon(MdiIcons.homeVariantOutline),
                activeIcon: Icon(MdiIcons.homeVariant)),
            BottomNavigationBarItem(
                title: const Text('News'), icon: Icon(MdiIcons.newspaper)),
            BottomNavigationBarItem(
                title: const Text('Favorites'),
                icon: Icon(Icons.star_border),
                activeIcon: Icon(Icons.star)),
          ]),
    );
  }

  Future<void> getStocksData() async {
    final List<Widget> list = <Widget>[];

    http.Response response = await http
        .get('https://api.iextrading.com/1.0/stock/market/list/gainers');
    final winners = json.decode(response.body);

    list.add(SDSectionHeader('Winners'));

    list.add(SizedBox(
      height: 50.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (BuildContext context, int index) => Row(
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
        .get('https://api.iextrading.com/1.0/stock/market/list/losers');
    final losers = json.decode(response.body);

    list.add(SDSectionHeader('Losers'));

    list.add(SizedBox(
      height: 50.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (BuildContext context, int index) => Row(
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

    list.add(const SizedBox(height: 20.0));

    final List<String> favs = await getFavs();
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
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (BuildContext context) => SearchPage())),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add),
              const SizedBox(width: 8.0),
              Text('ADD FAVORITES',
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
  }

  Future<void> getNewsData() async {
    final http.Response response = await http.get(newsUrl);
    final List jsonCode = json.decode(response.body) as List;

    setState(() {
      newsList = jsonCode;
    });
  }

  Future getCompanies() async {
    return storage.getCompanies();
  }

  String getName(String stockKey) {
    for (int i = 0; i < companies.length; i++) {
      if (companies[i].split(', ')[0] == stockKey) {
        return companies[i].split(', ')[1];
      }
    }

    return '';
  }

  Future<List<String>> getFavs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final List<String> favs = prefs.getStringList('favs');

    print(favs);

    if (favs != null) {
      if (favs.isNotEmpty) {
        return favs;
      }
    }

    return null;
  }

  Future<void> getFavorites() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      favoriteList = prefs.getStringList('favs');
    });
  }

  Future<void> updatePrefs(String companyId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('favs');
    if (favs != null) {
      if (!favs.contains(companyId)) {
        favs.add(companyId);
      } else {
        favs.remove(companyId);
      }
    } else {
      favs = <String>[companyId];
    }

    prefs.setStringList('favs', favs);
  }

  Widget _buildSearchButton() => IconButton(
        icon: Icon(Icons.search),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => SearchPage(),
          ),
        ),
      );
}

class CircleClipper extends CustomClipper<Rect> {
  CircleClipper(this.radius);

  double radius;

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
