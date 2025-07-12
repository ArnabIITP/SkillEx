import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> categories = ['All', 'Design', 'Coding', 'Music', 'Marketing'];
  int selectedCategoryIndex = 0;

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

  List<Map<String, String>> get filteredUsers {
    if (selectedCategoryIndex == 0) return userData;
    final selectedCategory = categories[selectedCategoryIndex].toLowerCase();
    return userData.where((user) =>
    user["skillsOffered"]!.toLowerCase().contains(selectedCategory) ||
        user["skillsWanted"]!.toLowerCase().contains(selectedCategory)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome 👋',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by skill (e.g., Photoshop)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),

            // Categories
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final isSelected = index == selectedCategoryIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(categories[index]),
                      selected: isSelected,
                      selectedColor: Colors.indigo,
                      backgroundColor: Colors.grey[300],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      onSelected: (_) {
                        setState(() => selectedCategoryIndex = index);
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),

            // Skill Swap User Cards
            Expanded(
              child: filteredUsers.isEmpty
                  ? Center(child: Text("No users found in this category."))
                  : ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(user["photoUrl"]!),
                      ),
                      title: Text(
                        user["name"]!,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("🛠️ Offers: ${user["skillsOffered"]}"),
                            Text("🎯 Wants: ${user["skillsWanted"]}"),
                            Text("⏰ ${user["availability"]}"),
                          ],
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
