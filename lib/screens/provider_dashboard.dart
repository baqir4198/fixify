import 'package:flutter/material.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  // --- Dashboard Logic Variables ---
  bool isOnline = true;
  double totalEarnings = 15450.0;
  int jobsDone = 24;
  double rating = 4.8;

  // --- Dummy Data Lists ---
  List<Map<String, String>> newRequests = [
    {"id": "1", "name": "Hamza Ahmad", "service": "Plumbing Leakage", "time": "10:30 AM", "price": "1200"},
    {"id": "2", "name": "Ali Khan", "service": "Pipe Repair", "time": "02:00 PM", "price": "800"},
  ];

  List<Map<String, String>> activeJobs = [
    {"id": "101", "name": "Sara Ali", "service": "Washing Machine Repair", "price": "1500"}
  ];

  // --- 1. Accept Request ---
  void acceptRequest(int index) {
    setState(() {
      activeJobs.add({
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "name": newRequests[index]['name']!,
        "service": newRequests[index]['service']!,
        "price": newRequests[index]['price']!, // Price bhi saath le kar jao
      });
      newRequests.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Job Accepted! Added to Active Jobs."), backgroundColor: Colors.blue),
    );
  }

  // --- 2. Reject Request ---
  void rejectRequest(int index) {
    setState(() {
      newRequests.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request Rejected"), backgroundColor: Colors.red),
    );
  }

  // --- 3. Finish/Complete Job Logic ---
  void completeJob(int index) {
    // Job ki price nikal kar total mein add karo
    double jobAmount = double.parse(activeJobs[index]['price'] ?? "0");

    setState(() {
      totalEarnings += jobAmount; // Paise barh gaye
      jobsDone += 1;             // Kaam barh gaya
      activeJobs.removeAt(index); // List se khatam
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Job Completed! Rs. ${jobAmount.toInt()} added to earnings."),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Provider Dashboard",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Row(
            children: [
              Text(isOnline ? "Online" : "Offline",
                  style: TextStyle(color: isOnline ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
              Switch(
                value: isOnline,
                activeColor: Colors.green,
                onChanged: (value) {
                  setState(() => isOnline = value);
                },
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Welcome Back,", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const Text("Bhai Experts 👋", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // --- Earnings Card ---
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOnline
                      ? [Colors.blue[900]!, Colors.blue[600]!]
                      : [Colors.grey[800]!, Colors.grey[600]!],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Earnings", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 10),
                  Text("Rs. ${totalEarnings.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat("Jobs Done", jobsDone.toString()),
                      _buildMiniStat("Rating", "$rating ★"),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- New Requests Section ---
            const Text("New Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            if (newRequests.isEmpty)
              const Center(child: Text("No new requests", style: TextStyle(color: Colors.grey)))
            else
              ...newRequests.asMap().entries.map((entry) {
                int idx = entry.key;
                var req = entry.value;
                return _buildRequestCard(
                  req['name']!,
                  req['service']!,
                  req['time']!,
                  req['price']!,
                  onAccept: () => acceptRequest(idx),
                  onReject: () => rejectRequest(idx),
                );
              }).toList(),

            const SizedBox(height: 30),
            const Text("Active Jobs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // --- Active Jobs List ---
            if (activeJobs.isEmpty)
              const Center(child: Text("No active jobs", style: TextStyle(color: Colors.grey)))
            else
              ...activeJobs.asMap().entries.map((entry) {
                int idx = entry.key;
                var job = entry.value;
                return _buildActiveJobCard(job['name']!, job['service']!, idx);
              }).toList(),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRequestCard(String name, String service, String time, String price, {required VoidCallback onAccept, required VoidCallback onReject}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 25, backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(service, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              Text("Rs. $price", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Spacer(),
              TextButton(onPressed: onReject, child: const Text("Reject", style: TextStyle(color: Colors.red))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Accept", style: TextStyle(color: Colors.white)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActiveJobCard(String name, String service, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.directions_run, color: Colors.green),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(service, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => completeJob(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Finish", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}