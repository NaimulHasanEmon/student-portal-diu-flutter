import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/student_model.dart';
import '../providers/student_provider.dart';
import '../providers/network_provider.dart';

class StudentInfoScreen extends StatefulWidget {
  final String? studentId;
  
  const StudentInfoScreen({
    super.key,
    this.studentId,
  });

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Set the student ID from URL if available
    if (widget.studentId != null) {
      _studentIdController.text = widget.studentId!;
    }
    
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
    
    // Fetch student info if ID is provided
    if (widget.studentId != null && widget.studentId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final studentProvider = Provider.of<StudentProvider>(context, listen: false);
        studentProvider.fetchStudentInfo(widget.studentId!);
      });
    }
  }
  
  @override
  void dispose() {
    _studentIdController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final networkProvider = Provider.of<NetworkProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Information'),
        elevation: 0,
      ),
      body: !networkProvider.isOnline
          ? _buildOfflineMessage()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInputSection(studentProvider),
                  const SizedBox(height: 20),
                  if (studentProvider.loading)
                    _buildLoadingIndicator()
                  else if (studentProvider.error != null)
                    _buildErrorMessage(studentProvider.error!)
                  else if (studentProvider.student != null)
                    _buildStudentInformation(studentProvider.student!)
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
  
  Widget _buildInputSection(StudentProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Enter Your Student ID',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3949AB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (provider.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Student ID',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3949AB),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _studentIdController,
                          decoration: InputDecoration(
                            hintText: 'e.g. 221-15-5601',
                            prefixIcon: const Icon(Icons.person, color: Color(0xFF3949AB)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your student ID';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Color(0xFF3949AB),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Enter your student ID with dashes (e.g. 221-15-5601)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.loading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                final studentId = _studentIdController.text.trim();
                                provider.fetchStudentInfo(studentId);
                                
                                // Update URL to reflect the student ID
                                context.go('/student-info/$studentId');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF3949AB),
                        disabledBackgroundColor: Colors.indigo.shade200,
                      ),
                      child: provider.loading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Loading...'),
                              ],
                            )
                          : const Text('View Student Information'),
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
              'Loading student information...',
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
                if (widget.studentId != null) {
                  final provider = Provider.of<StudentProvider>(context, listen: false);
                  provider.fetchStudentInfo(widget.studentId!);
                }
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
  
  Widget _buildStudentInformation(Student student) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: Color(0xFF3949AB),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    student.studentName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      student.studentId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Academic Information
                  _buildSectionHeader(
                    title: 'Academic Information',
                    icon: Icons.school,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    label: 'Program',
                    value: student.programName,
                  ),
                  _buildInfoRow(
                    label: 'Department',
                    value: student.departmentName,
                  ),
                  _buildInfoRow(
                    label: 'Faculty',
                    value: student.facultyName,
                  ),
                  _buildInfoRow(
                    label: 'Batch',
                    value: student.batchNo,
                  ),
                  const Divider(height: 32),
                  
                  // Additional Information
                  _buildSectionHeader(
                    title: 'Additional Information',
                    icon: Icons.info,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    label: 'Campus',
                    value: student.campusName,
                  ),
                  _buildInfoRow(
                    label: 'Shift',
                    value: student.shift,
                  ),
                  _buildInfoRow(
                    label: 'Program Type',
                    value: student.programType,
                  ),
                  _buildInfoRow(
                    label: 'Current Semester',
                    value: student.semesterName,
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.go('/result/${student.studentId}');
                          },
                          icon: const Icon(Icons.assessment),
                          label: const Text('Check Results'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.go('/student-details/${student.studentId}');
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('View Details'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF3949AB),
          size: 20,
        ),
        const SizedBox(width: 8),
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
  
  Widget _buildInfoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 