import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/network_provider.dart';
import '../providers/result_provider.dart';
import '../models/result_model.dart';

class ResultScreen extends StatefulWidget {
  final String? studentId;
  final String? semesterId;

  const ResultScreen({
    super.key,
    this.studentId,
    this.semesterId,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _semesterIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _studentId;
  String? _semesterId;

  @override
  void initState() {
    super.initState();
    _studentId = widget.studentId;
    _semesterId = widget.semesterId;
    
    if (_studentId != null) {
      _studentIdController.text = _studentId!;
    }
    
    if (_semesterId != null) {
      _semesterIdController.text = _semesterId!;
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Fetch result if both IDs are provided
    if (_studentId != null && _semesterId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final resultProvider = Provider.of<ResultProvider>(context, listen: false);
        resultProvider.fetchResult(_studentId!, _semesterId!);
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _studentIdController.dispose();
    _semesterIdController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final studentId = _studentIdController.text.trim();
      final semesterId = _semesterIdController.text.trim();
      
      final resultProvider = Provider.of<ResultProvider>(context, listen: false);
      resultProvider.fetchResult(studentId, semesterId);
      
      setState(() {
        _studentId = studentId;
        _semesterId = semesterId;
      });
      
      // Update URL without triggering a navigation
      if (context.mounted) {
        context.go('/result/$studentId/$semesterId');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkProvider = Provider.of<NetworkProvider>(context);
    final resultProvider = Provider.of<ResultProvider>(context);
    final bool isOnline = networkProvider.isOnline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_studentId != null) {
              context.go('/student-info/$_studentId');
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: !isOnline
          ? _buildOfflineMessage()
          : (_studentId == null || _semesterId == null)
              ? _buildInputSection()
              : Column(
                  children: [
                    if (_studentId != null && _semesterId != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Results for Student ID: $_studentId, Semester: $_semesterId',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Expanded(
                      child: resultProvider.loading
                          ? _buildLoadingIndicator()
                          : resultProvider.error != null
                              ? _buildErrorMessage(resultProvider.error!)
                              : _buildResultContent(resultProvider),
                    ),
                  ],
                ),
    );
  }

  Widget _buildOfflineMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.signal_wifi_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'You are offline',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your internet connection',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Provider.of<NetworkProvider>(context, listen: false).checkConnectivity();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Check Your Result',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                hintText: 'Enter your student ID',
                prefixIcon: Icon(Icons.person),
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your student ID';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _semesterIdController,
              decoration: const InputDecoration(
                labelText: 'Semester',
                hintText: 'Enter semester (e.g., Fall 2023)',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitForm(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the semester';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submitForm,
              icon: const Icon(Icons.search),
              label: const Text('View Result'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitDoubleBounce(
            color: Theme.of(context).primaryColor,
            size: 50.0,
            controller: _animationController,
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading result...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load result',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              error,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_studentId != null && _semesterId != null) {
                Provider.of<ResultProvider>(context, listen: false)
                    .fetchResult(_studentId!, _semesterId!);
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent(ResultProvider resultProvider) {
    final result = resultProvider.result;
    
    if (result == null) {
      return const Center(
        child: Text(
          'No result data available',
          style: TextStyle(fontSize: 18),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildInfoRow('Semester GPA', result.semesterGpa?.toString() ?? 'N/A'),
                  _buildInfoRow('CGPA', result.cgpa?.toString() ?? 'N/A'),
                  _buildInfoRow('Completed Credits', result.completedCredits?.toString() ?? 'N/A'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          if (result.courses != null && result.courses!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Courses',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    ...result.courses!.map((course) => _buildCourseItem(course)),
                  ],
                ),
              ),
            ),
            
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Implement PDF generation and download functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF download functionality will be implemented soon'),
                    ),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Reset the form to check another result
                  setState(() {
                    _studentId = null;
                    _semesterId = null;
                    _studentIdController.clear();
                    _semesterIdController.clear();
                  });
                  context.go('/result');
                },
                icon: const Icon(Icons.refresh),
                label: const Text('New Search'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCourseItem(dynamic course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.courseCode ?? 'Unknown Code',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            course.courseName ?? 'Unknown Course',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCourseDetail('Credit', course.credit?.toString() ?? 'N/A'),
              _buildCourseDetail('Grade', course.grade ?? 'N/A'),
              _buildCourseDetail('GPA', course.gradePoint?.toString() ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCourseDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
} 