import React, { useEffect, useState } from "react";
import { db, ref, onValue } from "./firebase";

function App() {
  const [data, setData] = useState({
    temperature: "--",
    humidity: "--",
    timestamp: "--"
  });

  useEffect(() => {
    const dataRef = ref(db, "solarDryer");
    onValue(dataRef, (snapshot) => {
      const val = snapshot.val();
      if (val) {
        setData(val);
      }
    });
  }, []);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-100 to-green-100 font-sans">
      <div className="bg-white rounded-2xl shadow-xl p-8 max-w-md w-full">
        <h1 className="text-3xl font-bold text-center mb-6 text-gray-800">☀️ Solar Dryer Monitor</h1>

        <div className="space-y-4">
          <div className="p-4 rounded-lg bg-blue-50 border border-blue-200">
            <p className="text-gray-600 text-sm">Temperature</p>
            <h2 className="text-2xl font-semibold text-blue-700">{data.temperature} °C</h2>
          </div>
          <div className="p-4 rounded-lg bg-green-50 border border-green-200">
            <p className="text-gray-600 text-sm">Humidity</p>
            <h2 className="text-2xl font-semibold text-green-700">{data.humidity} %</h2>
          </div>
          <div className="p-3 bg-gray-100 text-gray-500 text-sm rounded-md text-center">
            Last updated: {data.timestamp}
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
