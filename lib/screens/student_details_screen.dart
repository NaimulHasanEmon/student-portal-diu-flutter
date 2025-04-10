import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/student_model.dart';
import '../providers/student_provider.dart';
import '../providers/network_provider.dart';

class StudentDetailsScreen extends StatefulWidget {
  final String studentId;
  
  const StudentDetailsScreen({
    super.key, 
    required this.studentId,
  });

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
    
    // Fetch student details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      studentProvider.fetchStudentDetails(widget.studentId);
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final networkProvider = Provider.of<NetworkProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        elevation: 0,
      ),
      body: !networkProvider.isOnline
          ? _buildOfflineMessage()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (studentProvider.loading)
                    _buildLoadingIndicator()
                  else if (studentProvider.error != null)
                    _buildErrorMessage(studentProvider.error!)
                  else if (studentProvider.student != null)
                    _buildStudentDetails(studentProvider.student!)
                ],
              ),
            ),
    );
  }

  Widget _buildOfflineMessage() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade700),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'You are offline',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final provider = Provider.of<NetworkProvider>(context, listen: false);
                provider.checkConnection();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinKitFadingCircle(
              color: Color(0xFF3949AB),
              size: 50.0,
            ),
            SizedBox(height: 16),
            Text(
              'Loading student details...',
              style: TextStyle(color: Color(0xFF3949AB)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, color: Colors.red.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error Loading Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            error,
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final provider = Provider.of<StudentProvider>(context, listen: false);
                provider.fetchStudentDetails(widget.studentId);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStudentDetails(Student student) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Student Profile Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFF3949AB),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        student.studentName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'ID: ${student.studentId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Basic Information
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        title: 'Basic Information',
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.school,
                        label: 'Program',
                        value: student.programName,
                      ),
                      _buildInfoRow(
                        icon: Icons.business,
                        label: 'Department',
                        value: student.departmentName,
                      ),
                      _buildInfoRow(
                        icon: Icons.account_balance,
                        label: 'Faculty',
                        value: student.facultyName,
                      ),
                      _buildInfoRow(
                        icon: Icons.groups,
                        label: 'Batch',
                        value: student.batchNo,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Academic Information Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    title: 'Academic Information',
                    icon: Icons.school,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.location_city,
                    label: 'Campus',
                    value: student.campusName,
                  ),
                  _buildInfoRow(
                    icon: Icons.access_time,
                    label: 'Shift',
                    value: student.shift,
                  ),
                  _buildInfoRow(
                    icon: Icons.cast_for_education,
                    label: 'Program Type',
                    value: student.programType,
                  ),
                  _buildInfoRow(
                    icon: Icons.date_range,
                    label: 'Current Semester',
                    value: student.semesterName,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.go('/student-info/${student.studentId}');
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Info'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go('/result/${student.studentId}');
                  },
                  icon: const Icon(Icons.assessment),
                  label: const Text('View Results'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3949AB).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF3949AB),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3949AB),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 