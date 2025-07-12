import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _filterStatus = 'Pending';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  final List<String> _filterOptions = ['All', 'Pending', 'Accepted', 'Rejected'];

  @override
  void initState() {
    super.initState();
    // Generate sample data when testing - comment out for production
    _generateSampleData();
  }

  // Method to generate sample request data for testing
  Future<void> _generateSampleData() async {
    if (currentUserId.isEmpty) return;

    // Check if we already have sample data
    final existingData = await FirebaseFirestore.instance
        .collection('swipeRequests')
        .where('toUserId', isEqualTo: currentUserId)
        .limit(1)
        .get();

    if (!existingData.docs.isEmpty) return; // Skip if data exists

    // Sample users with different statuses
    final sampleUsers = [
      {
        'fromName': 'Shreya Ghosal',
        'fromPhoto': 'https://via.placeholder.com/150',
        'skillsOffered': 'Web Script',
        'skillsWanted': 'Flutter',
        'status': 'Pending',
        'rating': '3.9'
      },
      {
        'fromName': 'John Smith',
        'fromPhoto': 'https://via.placeholder.com/150',
        'skillsOffered': 'UI Design',
        'skillsWanted': 'Python',
        'status': 'Rejected',
        'rating': '4.2'
      },
      {
        'fromName': 'Sarah Khan',
        'fromPhoto': 'https://via.placeholder.com/150',
        'skillsOffered': 'React Native',
        'skillsWanted': 'UI/UX',
        'status': 'Accepted',
        'rating': '4.8'
      },
      {
        'fromName': 'Mike Tyson',
        'fromPhoto': 'https://via.placeholder.com/150',
        'skillsOffered': 'Database Design',
        'skillsWanted': 'Mobile App',
        'status': 'Pending',
        'rating': '3.5'
      },
    ];

    // Add sample requests to Firestore
    for (var user in sampleUsers) {
      await FirebaseFirestore.instance.collection('swipeRequests').add({
        'fromUserId': 'sample_${user['fromName']}',
        'fromName': user['fromName'],
        'fromPhoto': user['fromPhoto'],
        'toUserId': currentUserId,
        'skillsOffered': user['skillsOffered'],
        'skillsWanted': user['skillsWanted'],
        'status': user['status'],
        'rating': user['rating'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _acceptRequest(String docId) async {
    await FirebaseFirestore.instance
        .collection('swipeRequests')
        .doc(docId)
        .update({'status': 'Accepted'});
    // You could add additional logic here for match confirmation
  }

  void _rejectRequest(String docId) async {
    await FirebaseFirestore.instance
        .collection('swipeRequests')
        .doc(docId)
        .update({'status': 'Rejected'});
  }

  // Build pagination number items
  List<Widget> _buildPaginationItems(int totalPages) {
    // Show all pages if total is 5 or less
    if (totalPages <= 5) {
      return List.generate(
        totalPages,
            (index) => _buildPageNumberItem(index + 1),
      );
    }

    // Otherwise show current page with neighbors and first/last page
    List<Widget> items = [];

    // Always add page 1
    items.add(_buildPageNumberItem(1));

    // Add ellipsis if needed
    if (_currentPage > 3) {
      items.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text('...', style: TextStyle(fontSize: 16)),
      ));
    }

    // Add pages around current page
    for (int i = math.max(2, _currentPage - 1);
    i <= math.min(totalPages - 1, _currentPage + 1);
    i++) {
      items.add(_buildPageNumberItem(i));
    }

    // Add ellipsis if needed
    if (_currentPage < totalPages - 2) {
      items.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text('...', style: TextStyle(fontSize: 16)),
      ));
    }

    // Always add last page if not already added
    if (totalPages > 1) {
      items.add(_buildPageNumberItem(totalPages));
    }

    return items;
  }

  // Build individual page number item
  Widget _buildPageNumberItem(int pageNumber) {
    final isCurrentPage = pageNumber == _currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => setState(() => _currentPage = pageNumber),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrentPage ? Colors.black : Colors.transparent,
          ),
          child: Center(
            child: Text(
              "$pageNumber",
              style: TextStyle(
                color: isCurrentPage ? Colors.white : Colors.black,
                fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Skill Swap Platform", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          const Center(
            child: Text("Home",
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  fontSize: 16,
                )
            ),
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                  FirebaseAuth.instance.currentUser?.photoURL ??
                      "https://via.placeholder.com/150"
              ),
            ),
          ),
        ],
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: currentUserId.isEmpty
            ? const Center(child: Text("Please log in to view requests."))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Title
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                "Swap request",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Filter & Search Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      items: _filterOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _filterStatus = newValue!;
                          _currentPage = 1; // Reset to first page on filter change
                        });
                      },
                      hint: const Text('Status'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      suffixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 1; // Reset to first page on search change
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Request Cards
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('swipeRequests')
                    .where('toUserId', isEqualTo: currentUserId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No requests yet."));
                  }

                  // Filter requests by status and search query
                  var filteredRequests = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    // Filter by status
                    if (_filterStatus != 'All' &&
                        (data['status'] ?? 'Pending') != _filterStatus) {
                      return false;
                    }

                    // Filter by search query
                    if (_searchQuery.isNotEmpty) {
                      final name = (data['fromName'] ?? '').toLowerCase();
                      final skills = (data['skillsOffered'] ?? '').toLowerCase() +
                          (data['skillsWanted'] ?? '').toLowerCase();
                      return name.contains(_searchQuery.toLowerCase()) ||
                          skills.contains(_searchQuery.toLowerCase());
                    }

                    return true;
                  }).toList();

                  // Pagination
                  int startIndex = (_currentPage - 1) * _itemsPerPage;
                  int endIndex = startIndex + _itemsPerPage;
                  if (endIndex > filteredRequests.length) {
                    endIndex = filteredRequests.length;
                  }

                  if (startIndex >= filteredRequests.length && _currentPage > 1) {
                    // Adjust page if we're beyond available data
                    setState(() {
                      _currentPage--;
                    });
                    return const Center(child: CircularProgressIndicator());
                  }

                  var paginatedRequests = filteredRequests.sublist(startIndex, endIndex);
                  int totalPages = (filteredRequests.length / _itemsPerPage).ceil();

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedRequests.length,
                          itemBuilder: (context, index) {
                            final doc = paginatedRequests[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final docId = doc.id;
                            final status = data['status'] ?? 'Pending';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Profile Photo and Rating
                                    Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.grey, width: 1),
                                          ),
                                          child: CircleAvatar(
                                            radius: 30,
                                            backgroundImage: NetworkImage(
                                                data["fromPhoto"] ?? "https://via.placeholder.com/150"
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          "rating",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          "${data['rating'] ?? '3.0'}/5",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),

                                    // User Info and Skills
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data["fromName"] ?? "User",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Text(
                                                "Skills Offered: ",
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  data["skillsOffered"] ?? "",
                                                  style: const TextStyle(fontSize: 13),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Text(
                                                "Skill wanted: ",
                                                style: TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  data["skillsWanted"] ?? "",
                                                  style: const TextStyle(fontSize: 13),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Status and Actions
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          "Status",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            color: status == 'Pending'
                                                ? const Color(0xFFFF9800) // Orange
                                                : status == 'Accepted'
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        if (status == 'Pending')
                                          Row(
                                            children: [
                                              ElevatedButton(
                                                onPressed: () => _acceptRequest(docId),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  minimumSize: const Size(60, 30),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                ),
                                                child: const Text(
                                                  "Accept",
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              ElevatedButton(
                                                onPressed: () => _rejectRequest(docId),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  minimumSize: const Size(60, 30),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                ),
                                                child: const Text(
                                                  "Reject",
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Pagination Controls
                      if (totalPages > 1)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Left arrow
                              InkWell(
                                onTap: _currentPage > 1
                                    ? () => setState(() => _currentPage--)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.chevron_left,
                                    color: _currentPage > 1 ? Colors.black : Colors.grey,
                                  ),
                                ),
                              ),

                              // Page numbers
                              ..._buildPaginationItems(totalPages),

                              // Right arrow
                              InkWell(
                                onTap: _currentPage < totalPages
                                    ? () => setState(() => _currentPage++)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.chevron_right,
                                    color: _currentPage < totalPages ? Colors.black : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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
