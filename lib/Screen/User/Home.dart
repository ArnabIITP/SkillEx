import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> categories = ['All', 'Design', 'Coding', 'Music', 'Marketing'];
  int selectedCategory = 0;
  String searchQuery = '';

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
    // Filter users by search and category
    final filteredUsers = userData.where((user) {
      final matchesCategory = selectedCategory == 0 ||
          user["skillsOffered"]!.toLowerCase().contains(categories[selectedCategory].toLowerCase()) ||
          user["skillsWanted"]!.toLowerCase().contains(categories[selectedCategory].toLowerCase());
      final matchesSearch = searchQuery.isEmpty ||
          user["skillsOffered"]!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          user["skillsWanted"]!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          user["name"]!.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage("https://randomuser.me/api/portraits/men/32.jpg"),
              radius: 20,
            ),
            SizedBox(width: 12),
            Text(
              'Skill Swap',
              style: TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.indigo),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back 👋',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
            ),
            SizedBox(height: 6),
            Text(
              'Find the perfect skill swap partner!',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 18),

            // Search Bar
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(16),
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by skill or name...',
                  prefixIcon: Icon(Icons.search, color: Colors.indigo),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 18),

            // Categories
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = selectedCategory == index;
                  return ChoiceChip(
                    label: Text(categories[index]),
                    selected: isSelected,
                    selectedColor: Colors.indigo,
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.indigo,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => selectedCategory = index),
                  );
                },
              ),
            ),
            SizedBox(height: 18),

            // User Cards
            Expanded(
              child: filteredUsers.isEmpty
                  ? Center(
                      child: Text(
                        "No users found.",
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          margin: const EdgeInsets.only(bottom: 18),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundImage: NetworkImage(user["photoUrl"]!),
                                ),
                                SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user["name"]!,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo[900],
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.handyman, size: 18, color: Colors.indigo),
                                          SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              "Offers: ${user["skillsOffered"]}",
                                              style: TextStyle(fontSize: 15),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.lightbulb, size: 18, color: Colors.amber[700]),
                                          SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              "Wants: ${user["skillsWanted"]}",
                                              style: TextStyle(fontSize: 15),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 18, color: Colors.green),
                                          SizedBox(width: 4),
                                          Text(
                                            user["availability"]!,
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  icon: Icon(Icons.swap_horiz, size: 18),
                                  label: Text("Request Swap"),
                                  onPressed: () {
                                    // TODO: Implement swap request logic
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Swap request sent to ${user["name"]}!')),
                                    );
                                  },
                                ),
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
