/// Timeseries chart example
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class TimeSeriesChart extends StatefulWidget {
  const TimeSeriesChart(this.seriesList, {this.animate, this.interactive});

  final List<charts.Series> seriesList;
  final bool animate, interactive;

  factory TimeSeriesChart.fromData(List<TimeSeriesSales> data,
          {bool interactive = false, bool animate = true}) =>
      TimeSeriesChart(_getCurves(data),
          animate: animate, interactive: interactive);

  @override
  TimeSeriesChartState createState() {
    return TimeSeriesChartState();
  }

  static List<charts.Series<TimeSeriesSales, DateTime>> _getCurves(
    List<TimeSeriesSales> data,
  ) {
    return [
      charts.Series<TimeSeriesSales, DateTime>(
        id: 'Sales',
        colorFn: (_, __) => const charts.Color(r: 105, g: 240, b: 174),
        domainFn: (TimeSeriesSales sales, _) => sales.time,
        measureFn: (TimeSeriesSales sales, _) => sales.sales,
        data: data,
      ),
      charts.Series<TimeSeriesSales, DateTime>(
        id: 'Average',
        colorFn: (_, __) => const charts.Color(r: 105, g: 240, b: 174, a: 127),
        dashPatternFn: (_, __) => [2, 2],
        domainFn: (TimeSeriesSales sales, _) => sales.time,
        measureFn: (TimeSeriesSales sales, _) => sales.sales,
        data: <TimeSeriesSales>[
          TimeSeriesSales(data[0].time, averageSale(data)),
          TimeSeriesSales(data[data.length - 1].time, averageSale(data))
        ],
      ),
    ];
  }

  static double averageSale(List<TimeSeriesSales> data) {
    double avg = 0.0;

    for (final TimeSeriesSales item in data) {
      avg += item.sales;
    }

    return avg / data.length;
  }
}

class TimeSeriesChartState extends State<TimeSeriesChart> {
  DateTime _time;
  Map<String, num> _measures;

  void _onSelectionChanged(charts.SelectionModel model) {
    final List<charts.SeriesDatum> selectedDatum = model.selectedDatum;

    DateTime time;
    final Map<String, num> measures = <String, num>{};

    if (selectedDatum.isNotEmpty) {
      time = selectedDatum.first.datum.time;

      for (final charts.SeriesDatum datumPair in selectedDatum) {
        measures[datumPair.series.displayName] = datumPair.datum.sales;
      }
    }

    // Request a build.
    setState(() {
      _time = time;
      _measures = measures;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.interactive,
      child: Column(
        children: <Widget>[
          Expanded(
            child: charts.TimeSeriesChart(
              widget.seriesList,
              animate: widget.animate,
              animationDuration: const Duration(milliseconds: 250),
              behaviors: [
                charts.LinePointHighlighter(
                    showVerticalFollowLine:
                        charts.LinePointHighlighterFollowLineType.nearest),
                charts.SelectNearest(
                    eventTrigger: charts.SelectionTrigger.tapAndDrag),
              ],
              selectionModels: [
                charts.SelectionModelConfig(
                  type: charts.SelectionModelType.info,
                  changedListener: _onSelectionChanged,
                )
              ],
              domainAxis: charts.DateTimeAxisSpec(
                  showAxisLine: false,
                  renderSpec: charts.SmallTickRendererSpec(

                      // Tick and Label styling here.
                      labelStyle: charts.TextStyleSpec(
                          // size in Pts.
                          color: charts.MaterialPalette.transparent),

                      // Change the line colors to match text color.
                      lineStyle: charts.LineStyleSpec(
                          color: charts.MaterialPalette.transparent))),
              primaryMeasureAxis: charts.NumericAxisSpec(
                showAxisLine: false,
                renderSpec: charts.GridlineRendererSpec(

                    // Tick and Label styling here.
                    labelStyle: charts.TextStyleSpec(
                        color: charts.MaterialPalette.transparent),

                    // Change the line colors to match text color.
                    lineStyle: charts.LineStyleSpec(
                        thickness: 0,
                        color: charts.MaterialPalette.transparent)),
                tickProviderSpec:
                    const charts.BasicNumericTickProviderSpec(zeroBound: false),
              ),
              dateTimeFactory: const charts.LocalDateTimeFactory(),
            ),
          ),
          if (widget.interactive)
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: _time == null
                        ? [const Center(child: Text('Select a point'))]
                        : [
                            Padding(
                              padding: const EdgeInsets.only(left: 100.0),
                              child: Row(
                                children: <Widget>[
                                  SizedBox(
                                      width: 50.0,
                                      child: Text(
                                        'Date: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      )),
                                  Text(_time != null
                                      ? (_time
                                              .toIso8601String()
                                              .split('T')[1]
                                              .startsWith('00:00')
                                          ? _time
                                              .toIso8601String()
                                              .split('T')[0]
                                          : _time
                                                  .toIso8601String()
                                                  .split('T')[0] +
                                              ', ' +
                                              _time
                                                  .toIso8601String()
                                                  .split('T')[1]
                                                  .substring(0, 5))
                                      : 'Select a point'),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 100.0),
                              child: Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 50.0,
                                    child: Text(
                                      'Price: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(_measures != null
                                      ? _measures.values.join()
                                      : '')
                                ],
                              ),
                            ),
                          ],
                  ),
                ),
              ],
            )
          else
            Container(),
        ],
      ),
    );
  }
}

/// Sample time series data type.
class TimeSeriesSales {
  TimeSeriesSales(this.time, this.sales);

  final DateTime time;
  final double sales;
}
