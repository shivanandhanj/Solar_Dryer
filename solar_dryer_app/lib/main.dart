import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'graph.dart';
import 'prediction_service.dart';
import 'dart:async';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());

}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {                                                    
    return MaterialApp(
      title: 'Solar Dryer Monitorr',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      themeMode: ThemeMode.system,
      home: DryerMonitoringDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DryerMonitoringDashboard extends StatefulWidget {
  @override
  _DryerMonitoringDashboardState createState() => _DryerMonitoringDashboardState();
}


class FanControlWidget extends StatefulWidget {
  const FanControlWidget({Key? key}) : super(key: key);

  @override
  State<FanControlWidget> createState() => _FanControlWidgetState();
}

class _FanControlWidgetState extends State<FanControlWidget> {
  double sliderValue = 100; // Default starting fan speed
  final DatabaseReference fanRef =
      FirebaseDatabase.instance.ref("/solarDryer/control/fanSpeed");

  @override
  void initState() {
    super.initState();

    // Listen for current fanSpeed in DB to keep slider synced
    fanRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          sliderValue = double.parse(event.snapshot.value.toString());
        });
      }
    });
  }

  void updateFanSpeed(int speed) {
    fanRef.set(speed); // Write to Firebase
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Fan Speed: ${sliderValue.toInt()}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Slider(
          value: sliderValue,
          min: 0,
          max: 255,
          divisions: 255,
          label: sliderValue.toInt().toString(),
          onChanged: (value) {
            setState(() {
              sliderValue = value;
            });
          },
          onChangeEnd: (value) {
            updateFanSpeed(value.toInt());
          },
        ),
      ],
    );
  }
}



class BuzzerControlWidget extends StatefulWidget {
  const BuzzerControlWidget({Key? key}) : super(key: key);

  @override
  State<BuzzerControlWidget> createState() => _BuzzerControlWidgetState();
}

class _BuzzerControlWidgetState extends State<BuzzerControlWidget> {
  bool buzzerOn = false;
  final DatabaseReference buzzerRef =
      FirebaseDatabase.instance.ref("/solarDryer/control/buzzer");

  @override
  void initState() {
    super.initState();

    // Sync with DB
    buzzerRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          buzzerOn = event.snapshot.value.toString() == "1";
        });
      }
    });
  }

  void updateBuzzer(bool value) {
    buzzerRef.set(value ? 1 : 0); // Write ON=1 / OFF=0 to Firebase
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Buzzer",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Switch(
          value: buzzerOn,
          onChanged: (value) {
            setState(() {
              buzzerOn = value;
            });
            updateBuzzer(value);
          },
        ),
      ],
    );
  }
}


class AutoModeControlWidget extends StatefulWidget {
  @override
  _AutoModeControlWidgetState createState() => _AutoModeControlWidgetState();
}

class _AutoModeControlWidgetState extends State<AutoModeControlWidget> {
  bool autoMode = false;
  final DatabaseReference autoModeRef =
      FirebaseDatabase.instance.ref("/solarDryer/control/automode");

  @override
  void initState() {
    super.initState();

    // Sync with DB
    autoModeRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          autoMode = event.snapshot.value.toString() == "1";
        });
      }
    });
  }

  void updateAutoMode(bool value) {
    autoModeRef.set(value ? 1 : 0); // Write ON=1 / OFF=0 to Firebase
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Auto Mode",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Switch(
          value: autoMode,
          onChanged: (value) {
            setState(() {
              autoMode = value;
            });
            updateAutoMode(value);
          },
        ),
      ],
    );
  }
}




class CollectorSelector extends StatefulWidget {
  @override
  _CollectorSelectorState createState() => _CollectorSelectorState();
}

class _CollectorSelectorState extends State<CollectorSelector> {
  final DatabaseReference setupRef =
      FirebaseDatabase.instance.ref("/solarDryer/latest/Collector_shape");

  String? selectedType;
  final List<String> collectorTypes = [
    "Cylinder_holes",
    "Cylinder_noholes",
    "V_holes",
    "V_noholes",
  ];

  @override
  void initState() {
    super.initState();

    // Listen for current selection from DB
    setupRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        String dbValue = event.snapshot.value.toString();

        // Ensure it's a valid type, otherwise reset to null
        if (collectorTypes.contains(dbValue)) {
          setState(() {
            selectedType = dbValue;
          });
        } else {
          setState(() {
            selectedType = null; // avoid Dropdown crash
          });
        }
      }
    });
  }

  void updateCollectorType(String type) {
    setupRef.set(type);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Collector Type:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        DropdownButton<String>(
          value: (selectedType != null &&
                  collectorTypes.contains(selectedType))
              ? selectedType
              : null, // ensures no invalid value
          hint: Text("Choose a collector type"),
          items: collectorTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type.replaceAll("_", " ").toUpperCase()),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                selectedType = newValue;
              });
              updateCollectorType(newValue);
            }
          },
        ),
      ],
    );
  }
}




class _DryerMonitoringDashboardState extends State<DryerMonitoringDashboard> with SingleTickerProviderStateMixin {
  String temperature = "Loading...";
  String humidity = "Loading...";
  String C_temperature = "Loading...";
  String C_humidity = "Loading...";
  String timestamp = "Loading...";

  String category = 'Fruits';
  String selectedItem = 'Watermelon';
  final Map<String, List<String>> categoryItems = {
    'Fruits': ['Watermelon', 'Mango', 'Apple', 'Banana', 'Grapes', 'Pineapple', 'Strawberry'],
    'Vegetables': ['Carrot', 'Spinach', 'Tomato', 'Bell Pepper', 'Onion', 'Potato', 'Zucchini'],

    'Nuts': [
    'Almonds',
    'Cashews',
    'Walnuts',
    'Pistachios',
    'Hazelnuts',
    
  ]
  };

  


  
  Map<String, Map<String, String>> fruitVegData = {
    'Watermelon': {'temperature': '18', 'humidity': '65'},
    'Mango': {'temperature': '25', 'humidity': '70'},
    'Carrot': {'temperature': '10', 'humidity': '80'},
    'Spinach': {'temperature': '12', 'humidity': '85'},
  };
  
  // Historical data for charts
  List<FlSpot> temperatureData = [];
  List<FlSpot> humidityData = [];
  
  // For tab controller
  late TabController _tabController;
  

  // Check optimal conditions
  bool isOptimalCondition = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Listen for real-time updates
    DatabaseReference ref = FirebaseDatabase.instance.ref("solarDryer/latest");
    ref.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map;
        
        setState(() {
          temperature = data['temperature']?.toString() ?? "N/A";
          humidity = data['humidity']?.toString() ?? "N/A";
          C_temperature=data['Collector_temperature']?.toString() ?? "N/A";
          C_humidity=data['Collector_humidity']?.toString() ?? "N/A";
         
          
          // Add timestamp if not available
          timestamp = data['timestamp']?.toString() ?? 
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
          
          // Update chart data - limit to last 10 data points
          if (temperatureData.length >= 10) temperatureData.removeAt(0);
          if (humidityData.length >= 10) humidityData.removeAt(0);
          
          double time = temperatureData.isEmpty ? 0 : temperatureData.last.x + 1;
          temperatureData.add(FlSpot(time, double.tryParse(temperature) ?? 0));
          humidityData.add(FlSpot(time, double.tryParse(humidity) ?? 0));
          
          // Check if conditions are optimal for drying
          double tempValue = double.tryParse(temperature) ?? 0;
          double humValue = double.tryParse(humidity) ?? 0;
          isOptimalCondition = (tempValue > 30 && humValue < 60);
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String itemTemp = fruitVegData[selectedItem]?['temperature'] ?? 'N/A';
    String itemHumid = fruitVegData[selectedItem]?['humidity'] ?? 'N/A';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Solar Dryer Monitor', 
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Manual refresh logic here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Refreshing data...'))
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Settings page navigation
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: "Dashboard"),
            Tab(icon: Icon(Icons.show_chart), text: "Charts"),
            Tab(icon: Icon(Icons.history), text: "History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          // _buildChartsTab(),
          GraphPage(),
          _buildHistoryTab(),
         
          
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add action to control dryer if needed
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Dryer Controls'),
              content: Text('Would you like to adjust dryer settings?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Control logic here
                    Navigator.pop(context);
                  },
                  child: Text('Confirm'),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.power_settings_new),
        tooltip: 'Control Dryer',
      ),
    );
  }

  Widget _buildDashboardTab() {

     String itemTemp = fruitVegData[selectedItem]?['temperature'] ?? 'N/A';
    String itemHumid = fruitVegData[selectedItem]?['humidity'] ?? 'N/A';
     bool isDataReady = int.tryParse(temperature) != null && int.tryParse(humidity) != null;

    

    return RefreshIndicator(
      onRefresh: () async {
        // Pull to refresh logic
        await Future.delayed(Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          
          children: [
           
            Text(
              'Current Conditions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 22),
            Row(
              children: [
  Expanded(child: _buildMetricCard(
    "Temperature",
    "$temperature °C",

    Icons.thermostat,
    Colors.orange[400]!,
    (temperature != "Loading..." && (double.tryParse(temperature) ?? 0) > 30) 
        ? Colors.green 
        : Colors.grey
  )),
  SizedBox(width: 16),
  Expanded(child: _buildMetricCard(
    "Humidity",
    "$humidity %",
    Icons.water_drop,
    Colors.blue[400]!,
    (humidity != "Loading..." && (double.tryParse(humidity) ?? 0) < 60)
        ? Colors.green 
        : Colors.grey
  )),
],
            ),
            SizedBox(height: 24),
             Text(
              'Collector Condition',
              style: TextStyle(fontSize: 22,   fontWeight: FontWeight.bold),
            ),
  SizedBox(height: 16),
             Row(
              children: [
  Expanded(child: _buildMetricCard(
    "Temperature",
    "$C_temperature °C",
    Icons.thermostat,
    Colors.orange[400]!,
    (C_temperature != "Loading..." && (double.tryParse(C_temperature) ?? 0) > 30) 
        ? Colors.green 
        : Colors.grey
  )),
  SizedBox(width: 16),
  Expanded(child: _buildMetricCard(
    "Humidity",
    "$C_humidity %",
    Icons.water_drop,
    Colors.blue[400]!,
    (C_humidity != "Loading..." && (double.tryParse(C_humidity) ?? 0) < 60)
        ? Colors.green 
        : Colors.grey
  )),
],
            ),
 

          SizedBox(height: 20),
          CollectorSelector(),


            SizedBox(height: 24),
            Text(
    'Fan Control',
    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
  ),
  SizedBox(height: 16),
  Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: FanControlWidget(),
    ),
  ),

  SizedBox(height: 24),
Text('AutoMode',
    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
SizedBox(height: 16),
Card(
  elevation: 4,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: AutoModeControlWidget(),
  ),
),


  SizedBox(height: 24),
Text('Buzzer Control',
    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
SizedBox(height: 16),
Card(
  elevation: 4,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: BuzzerControlWidget(),
  ),
),

         


          DryingPredictionCard(
            temperature: temperature,
            humidity: humidity,
          ),
       

              
            
          





            



            SizedBox(height: 16),
            _buildStatusCard(),
            SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Updated',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(timestamp),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Recommendations',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildRecommendationCard(),
            //  SizedBox(height: 16),
            
          ],
        ),
      ),
    );
  }


  
 
  Widget _buildMetricCard(String title, String value, IconData icon, Color color, Color borderColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      color: isOptimalCondition ? const Color.fromARGB(255, 143, 209, 149) : const Color.fromARGB(255, 233, 214, 151),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isOptimalCondition ? Icons.check_circle : Icons.info,
              color: isOptimalCondition ? Colors.green : Colors.amber,
              size: 32,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOptimalCondition ? 'Optimal Drying Conditions' : 'Suboptimal Conditions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isOptimalCondition 
                      ? 'Current conditions are ideal for drying your products'
                      : 'Current conditions may slow down the drying process',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Tips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(isOptimalCondition
              ? '• Perfect time to load the dryer with products\n'
                '• Ensure airflow vents are fully open\n'
                '• Check product moisture levels regularly'
              : '• Consider waiting for better conditions\n'
                '• Reduce the amount of product in the dryer\n'
                '• Ensure direct sunlight exposure'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temperature History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Container(
            height: 200,
            child: temperatureData.length < 2
                ? Center(child: Text('Collecting data...'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: temperatureData,
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          SizedBox(height: 32),
          Text(
            'Humidity History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Container(
            height: 200,
            child: humidityData.length < 2
                ? Center(child: Text('Collecting data...'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: humidityData,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    // Simulated history data - would be replaced with actual data from Firebase
    final historyEntries = [
      {'temp': '35.2', 'humidity': '45.6', 'time': '2025-05-09 12:53:33'},
      {'temp': '34.8', 'humidity': '48.2', 'time': '2025-05-09 12:54:33'},
      {'temp': '33.6', 'humidity': '51.3', 'time': '2025-05-09 12:55:33'},
      {'temp': '32.1', 'humidity': '53.7', 'time': '2025-05-09 12:56:33'},
      {'temp': '31.5', 'humidity': '56.2', 'time': '2025-05-09 12:57:33'},
    ];
    
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historical Data',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: historyEntries.length,
              itemBuilder: (context, index) {
                final entry = historyEntries[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      children: [
                        Icon(Icons.thermostat, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('${entry['temp']}°C'),
                        SizedBox(width: 24),
                        Icon(Icons.water_drop, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('${entry['humidity']}%'),
                      ],
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(entry['time']!),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.info_outline),
                      onPressed: () {
                        // Show detailed info
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class DryingPredictionCard extends StatefulWidget {
  final String temperature;
  final String humidity;

  const DryingPredictionCard({
    Key? key,
    required this.temperature,
    required this.humidity,
  }) : super(key: key);

  @override
  _DryingPredictionCardState createState() => _DryingPredictionCardState();
}

class _DryingPredictionCardState extends State<DryingPredictionCard> {
  final Map<String, List<String>> categoryItems = {
    'Fruit': ['Mango', 'Apple', 'Banana', 'Grapes', 'Pineapple', 'Strawberry', 'Watermelon'],
    'Vegetable': ['Carrot', 'Spinach', 'Tomato', 'Bell Pepper', 'Onion', 'Potato', 'Zucchini'],
    'Nut': ['Almonds', 'Cashews', 'Walnuts', 'Pistachios', 'Hazelnuts', 'Pecans', 'Brazil Nuts'],
  };

  late TextEditingController _temperatureController;
  String selectedCategory = 'Fruit';
  String selectedItem = 'Mango';
  String predictedTime = '';
  String predictedDays = '';
  String predictedDetailed='';
  bool isLoading = false;
  String errorMessage = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _temperatureController = TextEditingController(text: widget.temperature);
    // Trigger initial prediction after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debouncedPrediction();
    });
  }

  @override
  void didUpdateWidget(DryingPredictionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.temperature != widget.temperature) {
      _temperatureController.text = widget.temperature;
      _debouncedPrediction();
    }
  }

  void _onTemperatureChanged(String value) {
    // Cancel previous timer if it exists
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }
    
    // Set a new timer to debounce the API calls
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _debouncedPrediction();
    });
  }

  void _onSelectionChanged() {
    // Cancel any ongoing debounce
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }
    _debouncedPrediction();
  }

  void _debouncedPrediction() {
    final String temp = _temperatureController.text.trim();
    
    // Only predict if temperature is valid and not empty
    if (temp.isEmpty || double.tryParse(temp) == null) {
      setState(() {
        predictedTime = '';
        predictedDays = '';
        errorMessage = temp.isEmpty ? '' : 'Invalid temperature';
      });
      return;
    }

    calculatePrediction();
  }

  Future<void> calculatePrediction() async {
    final String temp = _temperatureController.text.trim();
    
    if (temp.isEmpty) {
      setState(() {
        predictedTime = '';
        predictedDays = '';
        errorMessage = '';
      });
      return;
    }

    final double? temperature = double.tryParse(temp);
    if (temperature == null) {
      setState(() {
        predictedTime = '';
        predictedDays = '';
        predictedDetailed = '';
        errorMessage = 'Please enter a valid number';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await PredictionService.predictDryingTime(
        produceType: selectedCategory,
        name: selectedItem,
        dryingTemperatureC: temperature,
      );

      final double minutes = result['predicted_drying_time_min'];
      final int hours = (minutes / 60).floor();
        final int remainingMinutes = (minutes % 60).round();
      final double days = minutes / (24 * 60);

      setState(() {
        predictedTime = '${hours}h ${remainingMinutes}m';
        predictedDays = '${days.toStringAsFixed(2)} days';
         predictedDetailed = '${hours} hours ${remainingMinutes} minutes';
        isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        errorMessage = 'Prediction failed: ${e.toString().replaceAll('Exception: ', '')}';
        predictedTime = '';
        predictedDays = '';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Drying Time Prediction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            SizedBox(height: 16),
            
            // Temperature Input
            TextFormField(
              controller: _temperatureController,
              decoration: InputDecoration(
                labelText: 'Temperature (°C)',
                border: OutlineInputBorder(),
                suffixText: '°C',
                suffixIcon: isLoading ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ) : null,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: _onTemperatureChanged,
            ),
            SizedBox(height: 16),
            
            Text(
              'Current Humidity: ${widget.humidity}%',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: 'Produce Category',
                border: OutlineInputBorder(),
              ),
              items: categoryItems.keys.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedCategory = newValue!;
                  selectedItem = categoryItems[newValue]!.first;
                });
                _onSelectionChanged();
              },
            ),
            SizedBox(height: 16),
            
            // Item Dropdown
            DropdownButtonFormField<String>(
              value: selectedItem,
              decoration: InputDecoration(
                labelText: 'Produce Item',
                border: OutlineInputBorder(),
              ),
              items: categoryItems[selectedCategory]!.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedItem = newValue!;
                });
                _onSelectionChanged();
              },
            ),
            SizedBox(height: 16),
            
            // Prediction Result - Always visible when available
            if (predictedTime.isNotEmpty && predictedDays.isNotEmpty)
  Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.green[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.green),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.timer, color: Colors.green[800], size: 24),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Predicted Drying Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.green[700]),
                  SizedBox(width: 4),
                  Text(
                    predictedTime,
                    style: TextStyle(fontSize: 14, color: Colors.green[700]),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.green[700]),
                  SizedBox(width: 4),
                  Text(
                    predictedDays,
                    style: TextStyle(fontSize: 14, color: Colors.green[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  )
            else if (isLoading)
              Container(
                padding: EdgeInsets.all(12),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.green)),
                    SizedBox(width: 12),
                    Text('Calculating...', style: TextStyle(color: Colors.green)),
                  ],
                ),
              )
            else if (errorMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red[800], fontSize: 14),
                ),
              )
            else
              SizedBox.shrink(),

            // Help text
            SizedBox(height: 8),
            Text(
              'Prediction updates automatically when you change temperature or selection',
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

