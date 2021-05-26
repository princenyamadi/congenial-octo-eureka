import 'package:flutter/material.dart';

class Musicvisualizer extends StatelessWidget {
  List<Color> colors = [
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.redAccent,
    Colors.yellowAccent
  ];
  List<int> duration = [900, 700, 600, 800, 500];

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: new List<Widget>.generate(
          10,
          (index) => VisualComponent(
              duration: duration[index % 5], color: colors[index % 4])),
    );
  }
}

class VisualComponent extends StatefulWidget {
  const VisualComponent(
      {Key key, @required this.duration, @required this.color})
      : super(key: key);

  final int duration;
  final Color color;

  @override
  _VisualComponentState createState() => _VisualComponentState();
}

class _VisualComponentState extends State<VisualComponent>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController animController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    animController = AnimationController(
        duration: Duration(milliseconds: widget.duration), vsync: this);
    final curvedAnimation =
        CurvedAnimation(parent: animController, curve: Curves.easeOutExpo);

    animation = Tween<double>(begin: 0, end: 100).animate(curvedAnimation)
      ..addListener(() {
        setState(() {});
      });
    animController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 10,
        decoration: BoxDecoration(
            color: widget.color, borderRadius: BorderRadius.circular(5)),
        height: animation.value);
  }
}
