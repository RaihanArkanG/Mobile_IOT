import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:async';
import 'color.dart';
import 'graph.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  double percentage = 0.0;
  String selectedOption = 'Opsi 1';
  double currentLiters = 0.0;
  double temperature = 0.0;
  double turbidity = 0.0;
  late PageController _pageController;
  late Timer _timer;
  bool isFirstLaunch = true;
  TextEditingController _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (isFirstLaunch) {
      _showTextBoxPopup();
      isFirstLaunch = false;
    } else {
      // Fetch data when not the first launch
      _fetchDataFromAPI();
    }
  }

  void _showTextBoxPopup() {
    Fluttertoast.showToast(
      msg: "Insert link in the text box:",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.backgroundColor,
      textColor: AppColors.textColor,
      timeInSecForIosWeb: 5,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Insert link in the text box:'),
          content: TextField(
            controller: _linkController,
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog and fetch data based on the link
                Navigator.of(context).pop();
                _fetchDataFromAPI();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Fetch data from the API
  Future<void> _fetchDataFromAPI() async {
    final url = Uri.parse(_linkController.text.isNotEmpty ? _linkController.text : 'https://f0cb-103-104-130-7.ngrok-free.app/api/sensordata');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          temperature = data['latestTemperature'] != null
              ? double.parse(data['latestTemperature'].toString())
              : temperature;
          currentLiters = data['latestDistance'] != null
              ? double.parse(data['latestDistance'].toString())
              : currentLiters;
          turbidity = data['latestTurbidity'] != null
              ? double.parse(data['latestTurbidity'].toString())
              : turbidity;
        });
      } else {
        print('Failed to fetch data: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  bool isWideLayout = false;

  @override
  Widget build(BuildContext context) {
    isWideLayout = MediaQuery
        .of(context)
        .size
        .width > 800;
    return SafeArea(
      child: isWideLayout ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  // Tampilan layout lebar
  Widget _buildWideLayout() {
    return PageView(
      controller: _pageController,
      children: [
        // Konten Halaman Utama dan Grafik
        Row(
          children: [
            Expanded(
              child: Scaffold(
                body: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 150.0,
                      floating: false,
                      pinned: true,
                      backgroundColor: AppColors.backgroundColor,
                      title: buildAppBarTitle(),
                      bottom: buildAppBarBottom(),
                    ),
                    SliverFillRemaining(
                      child: SingleChildScrollView(
                        child: buildContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(),
            Expanded(
              flex: 3,
              child: PageView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return GraphPage();  // Tampilkan konten GraphPage
                  }
                  return Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Text('Konten lain untuk Halaman ${index + 1}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Tampilan layout sempit
  Widget _buildNarrowLayout() {
    return PageView(
      controller: _pageController,
      children: [
        // Konten Halaman Utama
        DefaultTabController(
          length: 1,
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 150.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.backgroundColor,
                  title: buildAppBarTitle(),
                  bottom: buildAppBarBottom(),
                ),
                SliverFillRemaining(
                  child: SingleChildScrollView(
                    child: buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Konten Grafik
        GraphPage(),
      ],
    );
  }

  // Komponen judul AppBar
  Widget buildAppBarTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildIconButton(Icons.settings, () {}),
        Text(
          'BlueWater.co',
          style: TextStyle(
            fontSize: 20.0,
            color: AppColors.textColor,
          ),
        ),
        buildIconButton(Icons.notifications, () {}),
      ],
    );
  }

  // Tombol ikon AppBar
  Widget buildIconButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon),
      color: AppColors.primaryColor,
      onPressed: onPressed,
    );
  }

  // Komponen bawah AppBar
  PreferredSizeWidget buildAppBarBottom() {
    return PreferredSize(
      preferredSize: Size.fromHeight(100),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDivider(),
            SizedBox(height: 2),
            buildLocationDropdown(),
            buildDivider(),
          ],
        ),
      ),
    );
  }

  // Pembatas
  Widget buildDivider() {
    return Divider(
      color: AppColors.outlineColor,
    );
  }

  // Dropdown lokasi
  Widget buildLocationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildText('Lokasi Anda', fontSize: 16.0, color: AppColors.textColor),
        Container(
          width: double.infinity,
          child: buildDropdownButton(
            value: selectedOption,
            onChanged: (String? newValue) {
              setState(() {
                selectedOption = newValue!;
              });
            },
            items: ['Opsi 1', 'Opsi 2', 'Opsi 3']
                .map<DropdownMenuItem<String>>(
                  (String value) {
                return buildDropdownMenuItem(value);
              },
            )
                .toList(),
          ),
        ),
      ],
    );
  }

  // Teks dengan gaya tertentu
  Widget buildText(String text, {
    double fontSize = 14.0,
    Color color = AppColors.textColor,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
      ),
    );
  }

  // Item Dropdown
  DropdownMenuItem<String> buildDropdownMenuItem(String value) {
    return DropdownMenuItem<String>(
      value: value,
      child: Text(value),
    );
  }

  // Tombol Dropdown
  Widget buildDropdownButton({
    required String? value,
    required ValueChanged<String?> onChanged,
    required List<DropdownMenuItem<String>> items,
  }) {
    return DropdownButton<String>(
      isExpanded: true,
      value: value,
      onChanged: onChanged,
      items: items,
      elevation: 4,
      iconSize: 36,
    );
  }

  // Konten utama
  Widget buildContent() {
    return Column(
      children: [
        buildText(
          'Status Tangki Secara Keseluruhan',
          fontSize: 16.0,
          color: AppColors.textColor,
        ),
        buildCircularPercentIndicator(),
      ],
    );
  }

  // Indikator persentase lingkaran
  Widget buildCircularPercentIndicator() {
    return Column(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
            child: CircularPercentIndicator(
              animation: true,
              animationDuration: 10000,
              radius: 150,
              lineWidth: 20,
              percent: percentage,
              progressColor: AppColors.primaryColor,
              backgroundColor: AppColors.accentColor,
              circularStrokeCap: CircularStrokeCap.round,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildText(
                    '${currentLiters.toStringAsFixed(2)} CM',
                    fontSize: 30,
                    color: AppColors.accentColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider( // <-- Ini adalah pemisah
          thickness: 2.0,
          color: AppColors.outlineColor, // Asumsi Anda memiliki warna yang didefinisikan
        ),
        // Sisanya dari konten Anda di sini
        Container(
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.thermostat,
                    color: AppColors.textColor2,
                    size: 24,
                  ),
                  SizedBox(width: 8.0),
                  buildText(
                    'Suhu: ${temperature.toStringAsFixed(2)}°C',
                    fontSize: 18,
                    color: AppColors.textColor2,
                  ),
                ],
              ),
              SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.opacity,
                    color: AppColors.textColor2,
                    size: 24,
                  ),
                  SizedBox(width: 8.0),
                  buildText(
                    'Keruh: ${turbidity.toStringAsFixed(2)} NTU',
                    fontSize: 18,
                    color: AppColors.textColor2,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
