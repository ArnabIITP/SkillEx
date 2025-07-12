import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final List<String> categories = ['All', 'Design', 'Coding', 'Music', 'Marketing'];
  final List<Map<String, String>> userData = [
    {
      "name": "Aryan Singh",
      "skillsOffered": "Flutter, UI/UX",
      "skillsWanted": "Photoshop",
      "availability": "Weekends",
      "photoUrl": "https://via.placeholder.com/100"
    },
    {
      "name": "Sneha Roy",
      "skillsOffered": "Python, ML",
      "skillsWanted": "Guitar",
      "availability": "Evenings",
      "photoUrl": "https://via.placeholder.com/100"
    },
    {
      "name": "John Doe",
      "skillsOffered": "Public Speaking",
      "skillsWanted": "Web Design",
      "availability": "Anytime",
      "photoUrl": "https://via.placeholder.com/100"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Skill Swap'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome 👋',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by skill (e.g., Photoshop)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 12),

            // Categories
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(categories[index]),
                      backgroundColor: index == 0 ? Colors.indigo : Colors.grey[300],
                      labelStyle: TextStyle(
                        color: index == 0 ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12),

            // Skill Swap User Cards
            Expanded(
              child: ListView.builder(
                itemCount: userData.length,
                itemBuilder: (context, index) {
                  final user = userData[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(user["photoUrl"]!),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user["name"]!,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 6),
                                Text("🛠️ Offers: ${user["skillsOffered"]}"),
                                Text("🎯 Wants: ${user["skillsWanted"]}"),
                                Text("⏰ ${user["availability"]}"),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
