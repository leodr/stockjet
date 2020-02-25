import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:share/share.dart';

class NewsItem extends StatelessWidget {
  final Map news;
  final bool divider;

  NewsItem(this.news, {this.divider: true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
      child: Column(
        children: <Widget>[
          this.divider ? Divider(height: 16.0) : Container(),
          InkWell(
            onTap: () => _launchURL(context, news["url"]),
            borderRadius: BorderRadius.circular(6.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(news["source"].toString().toUpperCase()),
                            SizedBox(height: 4.0),
                            Text(
                              news["headline"],
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 18.0, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                      getImage(context)
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(news["datetime"].toString().split("T")[0],
                          style: TextStyle(color: Colors.grey)),
                      IconButton(
                          icon: Icon(Icons.share),
                          onPressed: () {
                            Share.share(news["headline"] + ": " + news["url"]);
                          })
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget getImage(context) {
    /*try {
      return news["image"] != null
          ? Card(
              child: CachedNetworkImage(
                imageUrl: news["image"],
                width: 100.0,
                placeholder: Container(
                  width: 100.0,
                  height: 100.0,
                  child: SpinKitDoubleBounce(
                    color: Theme.of(context).accentColor,
                  ),
                ),
                height: 100.0,
                fit: BoxFit.cover,
                errorWidget: Container(),
              ),
            )
          : Container();
    } catch (e) {*/
    return Container();
    //}
  }
}
