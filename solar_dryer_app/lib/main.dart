import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'graph.dart';
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

         
          DryingRecommendationCard(
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
      color: isOptimalCondition ? Colors.green[50] : Colors.amber[50],
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

class DryingRecommendationCard extends StatefulWidget {
   final String temperature;
  final String humidity;

  

  const DryingRecommendationCard({
    Key? key,
    required this.temperature,
    required this.humidity,
  }) : super(key: key);
  @override
  _DryingRecommendationCardState createState() => _DryingRecommendationCardState();
}

class _DryingRecommendationCardState extends State<DryingRecommendationCard> {

  final Map<String, List<String>> categoryItems = {
    'Fruits': ['Watermelon', 'Mango', 'Apple', 'Banana', 'Grapes', 'Pineapple', 'Strawberry'],
    'Vegetables': ['Carrot', 'Spinach', 'Tomato', 'Bell Pepper', 'Onion', 'Potato', 'Zucchini'],
     'Nuts': [
    'Almonds',
    'Cashews',
    'Walnuts',
    'Pistachios',
    'Hazelnuts',
    'Pecans',
    'Brazil Nuts',
    'Macadamia Nuts',
    'Chestnuts'
  ]
  };

  final Map<String, Map<String, Map<String, Map<String, String>>>> fruitVegData = {
    'Fruits': {
      'Watermelon': {
         '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '48'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '36'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '30'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '24'},
      },
      'Mango': {
        '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '36'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '30'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '24'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '18'},
      },
      'Apple': {
        '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '24'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '20'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '16'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '12'},
      },
      'Banana': {
        '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '30'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '24'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '20'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '16'},
      },
      'Grapes': {
        '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '48'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '40'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '32'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '24'},
      },
      'Pineapple': {
        '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '40'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '32'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '26'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '20'},
      },
      'Strawberry': {
        '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '24'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '18'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '15'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '12'},
      },
    },
    'Vegetables': {
      'Carrot': {
        '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '20'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '16'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '14'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '10'},
      },
      'Spinach': {
        '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '8'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '6'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '5'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '4'},
      },
      'Tomato': {
        '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '32'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '26'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '22'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '18'},
      },
      'Bell Pepper': {
        '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '24'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '20'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '16'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '12'},
      },
      'Onion': {
        '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '20'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '16'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '12'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '10'},
      },
      'Potato': {
        '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '30'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '24'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '20'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '16'},
      },
      'Zucchini': {
        '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '24'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '20'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '16'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '12'},
      },
    },

    'Nuts': {
      'Almonds': {
        '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '24'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '20'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '16'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '12'},
      },
      'Cashews': {
        '35_45': {'temperature': '35', 'humidity': '45', 'dryingTime': '24'},
        '40_40': {'temperature': '40', 'humidity': '40', 'dryingTime': '20'},
        '45_35': {'temperature': '45', 'humidity': '35', 'dryingTime': '16'},
        '50_30': {'temperature': '50', 'humidity': '30', 'dryingTime': '12'},
      },
      // Add more nuts data here
    },
  };
  late String currentTemp;
  late String currentHumidity;


  String selectedCategory = 'Fruits';
  String selectedItem = 'Watermelon';
  
  String predictedTime = '';

  @override
  void initState() {
    super.initState();
     currentTemp = widget.temperature;
    currentHumidity = widget.humidity;
    calculatePrediction();
  }

   @override
  void didUpdateWidget(covariant DryingRecommendationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.temperature != widget.temperature || oldWidget.humidity != widget.humidity) {
      currentTemp = widget.temperature;
      currentHumidity = widget.humidity;
      calculatePrediction();
    }
  }

  void calculatePrediction() {
    List<String> tempKeys = ['35_45', '40_40', '45_35', '50_30'];
    Map<String, int> timeByKey = {};

    for (var key in tempKeys) {
      var dataPoint = fruitVegData[selectedCategory]?[selectedItem]?[key];
      if (dataPoint != null && dataPoint['dryingTime'] != null) {
        timeByKey[key] = int.parse(dataPoint['dryingTime']!);
      }
    }

    String lookupKey = '';
    int temp = int.tryParse(currentTemp) ?? 40;
    int humidity = int.tryParse(currentHumidity) ?? 40;

    if (temp <= 37) lookupKey = '35_45';
    else if (temp <= 42) lookupKey = '40_40';
    else if (temp <= 47) lookupKey = '45_35';
    else lookupKey = '50_30';

    var dryingData = fruitVegData[selectedCategory]?[selectedItem]?[lookupKey];
    var dryingTime = dryingData?['dryingTime'];

    setState(() {
      predictedTime = dryingTime != null ? '$dryingTime hours' : 'Data not available';
    });
  }

  @override
  Widget build(BuildContext context) {
    // paste the UI part from your original _buildRecommendation() here
    // remove any internal variable declarations and just use `selectedCategory`, etc.
    // If you'd like, I can fill that in too.
   /* Your UI Code (the entire Card and dropdowns etc.) */

    
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Drying Time Prediction',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              
              // Category Dropdown
            Row(
                children: [
                  Icon(Icons.category, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Category:', style: TextStyle(fontWeight: FontWeight.w500)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          items: categoryItems.keys.map((String category) {
                            return DropdownMenuItem<String>(
                                value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedCategory = newValue;
                                // When category changes, update the item to the first one in the new category
                                selectedItem = categoryItems[newValue]!.first;
                                calculatePrediction();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              // Item Dropdown
              Row(
                children: [
                  Icon(Icons.eco, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Item:', style: TextStyle(fontWeight: FontWeight.w500)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedItem,
                          isExpanded: true,
                          items: categoryItems[selectedCategory]!.map((String item) {
                            return DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedItem = newValue;
                                
                                calculatePrediction();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // Temperature and Humidity Sliders
              Text(
                'Current Conditions:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              
              // Temperature Slider
              Row(
                children: [
                  Icon(Icons.thermostat, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Temperature: $currentTemp°C', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              Slider(
                value: double.parse(currentTemp),
                min: 30,
                max: 50,
                divisions: 15,
                activeColor: Colors.orange,
                label: currentTemp,
                onChanged: (double value) {
                  setState(() {
                    currentTemp = value.round().toString();
                    calculatePrediction();
                  });
                },
              ),
              SizedBox(height: 8),
              
              // Humidity Slider
              Row(
                children: [
                  Icon(Icons.water_drop, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Humidity: $currentHumidity%', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              Slider(
                value: double.parse(currentHumidity),
                min: 30,
                max: 70,
                divisions: 15,
                activeColor: Colors.blue,
                label: currentHumidity,
                onChanged: (double value) {
                  setState(() {
                    currentHumidity = value.round().toString();
                    calculatePrediction();
                  });
                },
              ),
              SizedBox(height: 24),
              
              // Results Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Estimated Drying Time',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer, size: 32, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          predictedTime,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'For $selectedItem at $currentTemp°C and $currentHumidity% humidity',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  }
}
