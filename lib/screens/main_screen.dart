import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/student_viewmodel.dart';
import '../models/payment.dart';
import '../models/student.dart';
import 'widgets/student_card.dart';
import 'widgets/student_details_sheet.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/student_history_dialog.dart';
import 'widgets/confirm_payment_dialog.dart';
import 'widgets/confirm_unpaid_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _batchController;
  late PageController _pageController;
  int _currentTabIndex = 0; // Now controls bottom navigation
  int _currentBatchIndex = 0;

  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _batchController = TabController(length: 2, vsync: this);

    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 1.0,
    );

    _batchController.addListener(() {
      setState(() {
        _currentBatchIndex = _batchController.index;
      });
      if (_pageController.hasClients && !_isSearchVisible) {
        _pageController.animateToPage(
          _currentBatchIndex,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    _searchController.addListener(() {
      final viewModel = Provider.of<StudentViewModel>(context, listen: false);
      viewModel.updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _batchController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: _isSearchVisible
              ? Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95)
              : null,
          appBar: viewModel.selectedStudentIds.isEmpty
              ? _buildMainAppBar(viewModel)
              : _buildSelectionAppBar(viewModel),
          body: Column(
            children: [
              if (!_isSearchVisible) _buildBatchTabs(),
              if (!_isSearchVisible && _currentTabIndex != 2) _buildPaymentSummaryBox(viewModel),
              if (_isSearchVisible) _buildPopupSearchBar(viewModel),
              Expanded(
                child: viewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _isSearchVisible
                    ? _buildSearchResults(viewModel)
                    : _buildHyperSensitiveSwipeContent(viewModel),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
          floatingActionButton: viewModel.selectedStudentIds.isEmpty && !_isSearchVisible
              ? FloatingActionButton(
            onPressed: () => _showAddStudentSheet(),
            child: const Icon(Icons.add),
          )
              : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildMainAppBar(StudentViewModel viewModel) {
    final monthFormatter = DateFormat('MMMM yyyy');
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final selectedMonth = DateTime(viewModel.selectedDate.year, viewModel.selectedDate.month);
    final isCurrentOrFutureMonth = selectedMonth.isAtSameMomentAs(currentMonth) || selectedMonth.isAfter(currentMonth);

    return AppBar(
      title: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: viewModel.goToPreviousMonth,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Month',
              ),
              Expanded(
                child: Center(
                  child: Text(
                    monthFormatter.format(viewModel.selectedDate),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: isCurrentOrFutureMonth ? null : viewModel.goToNextMonth,
                icon: Icon(
                  Icons.chevron_right,
                  color: isCurrentOrFutureMonth
                      ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.onSurface,
                ),
                tooltip: isCurrentOrFutureMonth
                    ? 'Cannot navigate to future months'
                    : 'Next Month',
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _toggleSearch,
          icon: CircleAvatar(
            radius: 18,
            backgroundColor: _isSearchVisible
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.search,
              color: _isSearchVisible
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          tooltip: 'Search Students',
        ),

        IconButton(
          onPressed: viewModel.toggleFeesVisibility,
          icon: CircleAvatar(
            radius: 18,
            backgroundColor: viewModel.isFeesVisible
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
            child: Icon(
              viewModel.isFeesVisible ? Icons.visibility : Icons.visibility_off,
              color: viewModel.isFeesVisible
                  ? Colors.white
                  : Theme.of(context).colorScheme.error,
              size: 20,
            ),
          ),
          tooltip: viewModel.isFeesVisible ? 'Hide Fee Amounts' : 'Show Fee Amounts',
        ),

        // UPDATED: Back to popup menu with Settings and Summary options
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'settings':
                _showSettingsDialog(context);
                break;
              case 'summary':
                _showSummaryDialog(context);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'summary',
              child: Row(
                children: [
                  Icon(Icons.analytics),
                  SizedBox(width: 12),
                  Text('Summary'),
                ],
              ),
            ),
          ],
          icon: const Icon(Icons.more_vert),
          tooltip: 'More options',
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(StudentViewModel viewModel) {
    return AppBar(
      leading: IconButton(
        onPressed: viewModel.clearSelection,
        icon: const Icon(Icons.close),
      ),
      title: Text('${viewModel.selectedStudentIds.length} selected'),
      actions: [
        IconButton(
          onPressed: viewModel.markSelectedAsPaid,
          icon: const Icon(Icons.done_all),
        ),
      ],
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      onTap: (index) {
        setState(() {
          _currentTabIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 8,
      selectedFontSize: 12,
      unselectedFontSize: 11,
      items: [
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _currentTabIndex == 0
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle,
              color: _currentTabIndex == 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          label: 'Paid',
          activeIcon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _currentTabIndex == 1
                  ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.pending,
              color: _currentTabIndex == 1
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          label: 'Unpaid',
          activeIcon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.pending,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _currentTabIndex == 2
                  ? Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.people,
              color: _currentTabIndex == 2
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          label: 'Students',
          activeIcon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.people,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: TabBar(
        controller: _batchController,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Batch 1'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Batch 2'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryBox(StudentViewModel viewModel) {
    // Get current batch number (1 or 2)
    final currentBatch = _currentBatchIndex + 1;

    // Filter students by current batch
    final batchStudents = viewModel.studentsWithStatus
        .where((s) => s.student.batch == currentBatch)
        .toList();

    final totalStudents = batchStudents.length;

    if (totalStudents == 0) {
      return const SizedBox.shrink(); // Don't show if no students
    }

    // Calculate statistics based on current tab
    String summaryText;
    Color backgroundColor;
    Color textColor;

    if (_currentTabIndex == 0) {
      // Paid tab
      final paidCount = batchStudents.where((s) => s.isPaid).length;
      final needToPay = totalStudents - paidCount;
      summaryText = '$paidCount paid out of $totalStudents students ($needToPay still needs to pay)';
      backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      textColor = Theme.of(context).colorScheme.onPrimaryContainer;
    } else {
      // Unpaid tab
      final unpaidCount = batchStudents.where((s) => !s.isPaid).length;
      final alreadyPaid = totalStudents - unpaidCount;
      summaryText = '$unpaidCount unpaid out of $totalStudents students ($alreadyPaid already paid)';
      backgroundColor = Theme.of(context).colorScheme.errorContainer;
      textColor = Theme.of(context).colorScheme.onErrorContainer;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // REDUCED: from vertical: 8 to 4
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // REDUCED: from vertical: 12 to 8
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _currentTabIndex == 0
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        summaryText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPopupSearchBar(StudentViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search by name across all batches...',
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.primary,
          ),
          suffixIcon: IconButton(
            onPressed: _closeSearch,
            icon: const Icon(Icons.clear),
            tooltip: 'Close Search',
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildSearchResults(StudentViewModel viewModel) {
    List<StudentWithPaymentStatus> allSearchResults;

    switch (_currentTabIndex) {
      case 0:
        allSearchResults = viewModel.studentsWithStatus
            .where((s) => s.isPaid)
            .toList();
        break;
      case 1:
        allSearchResults = viewModel.studentsWithStatus
            .where((s) => !s.isPaid)
            .toList();
        break;
      case 2:
      default:
        allSearchResults = viewModel.studentsWithStatus.toList();
        break;
    }

    if (allSearchResults.isEmpty) {
      return _buildSearchEmptyState(viewModel);
    }

    final batch1Results = allSearchResults.where((s) => s.student.batch == 1).toList();
    final batch2Results = allSearchResults.where((s) => s.student.batch == 2).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                '${allSearchResults.length} students found',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        if (batch1Results.isNotEmpty) ...[
          _buildBatchHeader('Batch 1', Colors.blue, batch1Results.length),
          ...batch1Results.map((studentWithStatus) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: StudentCard(
              studentWithStatus: studentWithStatus,
              isSelected: viewModel.selectedStudentIds.contains(studentWithStatus.student.id),
              currentTabIndex: _currentTabIndex,
              onStatusChange: (id, status) {
                if (status) {
                  _showConfirmPaymentDialog(context, studentWithStatus.student);
                } else {
                  _showConfirmUnpaidDialog(context, studentWithStatus.student);
                }
              },
              onDelete: (id) => _showDeleteConfirmation(context, id),
              onEdit: (student) => _showStudentDetailsSheet(context, student),
              onLongPress: (id) => viewModel.toggleStudentSelection(id),
              onTap: (id) {
                if (viewModel.selectedStudentIds.isNotEmpty) {
                  viewModel.toggleStudentSelection(id);
                } else if (_currentTabIndex == 2) {
                  _showStudentHistoryWithFeedback(context, studentWithStatus.student);
                } else {
                  _showStudentDetailsSheet(context, studentWithStatus.student);
                }
              },
            ),
          )),
          const SizedBox(height: 16),
        ],

        if (batch2Results.isNotEmpty) ...[
          _buildBatchHeader('Batch 2', Colors.green, batch2Results.length),
          ...batch2Results.map((studentWithStatus) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: StudentCard(
              studentWithStatus: studentWithStatus,
              isSelected: viewModel.selectedStudentIds.contains(studentWithStatus.student.id),
              currentTabIndex: _currentTabIndex,
              onStatusChange: (id, status) {
                if (status) {
                  _showConfirmPaymentDialog(context, studentWithStatus.student);
                } else {
                  _showConfirmUnpaidDialog(context, studentWithStatus.student);
                }
              },
              onDelete: (id) => _showDeleteConfirmation(context, id),
              onEdit: (student) => _showStudentDetailsSheet(context, studentWithStatus.student),
              onLongPress: (id) => viewModel.toggleStudentSelection(id),
              onTap: (id) {
                if (viewModel.selectedStudentIds.isNotEmpty) {
                  viewModel.toggleStudentSelection(id);
                } else if (_currentTabIndex == 2) {
                  _showStudentHistoryWithFeedback(context, studentWithStatus.student);
                } else {
                  _showStudentDetailsSheet(context, studentWithStatus.student);
                }
              },
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildBatchHeader(String batchName, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            batchName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyState(StudentViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No students found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (viewModel.searchQuery.isNotEmpty)
            Text(
              'No students found matching "${viewModel.searchQuery}" in both batches',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _closeSearch,
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildHyperSensitiveSwipeContent(StudentViewModel viewModel) {
    return PageView.builder(
      controller: _pageController,
      physics: const HyperSensitivePageScrollPhysics(),
      onPageChanged: (index) {
        setState(() {
          _currentBatchIndex = index;
        });
        _batchController.animateTo(index);
      },
      itemCount: 2,
      itemBuilder: (context, batchIndex) {
        return _buildTabContent(viewModel, batchIndex + 1);
      },
    );
  }

  Widget _buildTabContent(StudentViewModel viewModel, int batch) {
    final paidStudents = viewModel.studentsWithStatus
        .where((s) => s.isPaid && s.student.batch == batch)
        .toList();
    final unpaidStudents = viewModel.studentsWithStatus
        .where((s) => !s.isPaid && s.student.batch == batch)
        .toList();
    final allStudents = viewModel.studentsWithStatus
        .where((s) => s.student.batch == batch)
        .toList();

    List<StudentWithPaymentStatus> currentList;
    switch (_currentTabIndex) {
      case 0:
        currentList = paidStudents;
        break;
      case 1:
      // Sort unpaid students with overdue first
        currentList = unpaidStudents;
        currentList.sort((a, b) {
          // Overdue students first (true comes before false)
          if (a.isOverdue && !b.isOverdue) return -1;
          if (!a.isOverdue && b.isOverdue) return 1;
          // If both have same overdue status, sort alphabetically by name
          return a.student.name.toLowerCase().compareTo(b.student.name.toLowerCase());
        });
        break;
      case 2:
      default:
        currentList = allStudents;
        break;
    }

    if (currentList.isEmpty) {
      return _buildEmptyState(viewModel, batch);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,      // REDUCED: from 16 to 8
        bottom: 100,
      ),
      itemCount: currentList.length,
      itemBuilder: (context, index) {
        final studentWithStatus = currentList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: StudentCard(
            studentWithStatus: studentWithStatus,
            isSelected: viewModel.selectedStudentIds.contains(studentWithStatus.student.id),
            currentTabIndex: _currentTabIndex,
            onStatusChange: (id, status) {
              if (status) {
                _showConfirmPaymentDialog(context, studentWithStatus.student);
              } else {
                _showConfirmUnpaidDialog(context, studentWithStatus.student);
              }
            },
            onDelete: (id) => _showDeleteConfirmation(context, id),
            onEdit: (student) => _showStudentDetailsSheet(context, student),
            onLongPress: (id) => viewModel.toggleStudentSelection(id),
            onTap: (id) {
              if (viewModel.selectedStudentIds.isNotEmpty) {
                viewModel.toggleStudentSelection(id);
              } else if (_currentTabIndex == 2) {
                _showStudentHistoryWithFeedback(context, studentWithStatus.student);
              } else {
                _showStudentDetailsSheet(context, studentWithStatus.student);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(StudentViewModel viewModel, int batch) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final selectedMonth = DateTime(viewModel.selectedDate.year, viewModel.selectedDate.month);
    final isPastMonth = selectedMonth.isBefore(currentMonth);

    final hasNoStudentsInCurrentView = viewModel.studentsWithStatus
        .where((s) => s.student.batch == batch)
        .isEmpty;

    final batchColor = batch == 1 ? Colors.blue : Colors.green;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: batchColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school,
              size: 60,
              color: batchColor,
            ),
          ),
          const SizedBox(height: 16),
          if (isPastMonth && hasNoStudentsInCurrentView) ...[
            Text(
              'No Data In This Month',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: viewModel.goToPresentMonth,
              child: const Text('Go to Present Month'),
            ),
          ] else ...[
            Text(
              'No students in Batch $batch yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by adding your first student to Batch $batch',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });

    if (_isSearchVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    } else {
      _closeSearch();
    }
  }

  void _closeSearch() {
    setState(() {
      _isSearchVisible = false;
    });
    _searchController.clear();
    _searchFocusNode.unfocus();

    final viewModel = Provider.of<StudentViewModel>(context, listen: false);
    viewModel.updateSearchQuery('');
  }

  void _showAddStudentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StudentDetailsSheet(
        initialBatch: _currentBatchIndex + 1,
      ),
    );
  }

  void _showStudentDetailsSheet(BuildContext context, Student? student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StudentDetailsSheet(student: student),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  void _showSummaryDialog(BuildContext context) {
    final viewModel = Provider.of<StudentViewModel>(context, listen: false);

    // Calculate exact revenue based on actual student fees
    double totalExpectedRevenue = 0;
    double collectedRevenue = 0;
    double pendingRevenue = 0;

    for (var studentWithStatus in viewModel.studentsWithStatus) {
      final studentFee = studentWithStatus.student.fee;
      totalExpectedRevenue += studentFee;

      if (studentWithStatus.isPaid) {
        collectedRevenue += studentFee;
      } else {
        pendingRevenue += studentFee;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics),
            SizedBox(width: 8),
            Text('Summary'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummarySection(
                'Current Month Overview',
                [
                  'Total Students: ${viewModel.allStudents.length}',
                  'Batch 1: ${viewModel.allStudents.where((s) => s.batch == 1).length}',
                  'Batch 2: ${viewModel.allStudents.where((s) => s.batch == 2).length}',
                ],
              ),
              const SizedBox(height: 16),
              _buildSummarySection(
                'Payment Status',
                [
                  'Paid: ${viewModel.studentsWithStatus.where((s) => s.isPaid).length}',
                  'Unpaid: ${viewModel.studentsWithStatus.where((s) => !s.isPaid).length}',
                  'Overdue: ${viewModel.studentsWithStatus.where((s) => s.isOverdue).length}',
                ],
              ),
              const SizedBox(height: 16),
              _buildSummarySection(
                'Monthly Revenue',
                [
                  'Total Expected: ${viewModel.isFeesVisible ? "₹${totalExpectedRevenue.toStringAsFixed(0)}" : "Hidden"}',
                  'Collected: ${viewModel.isFeesVisible ? "₹${collectedRevenue.toStringAsFixed(0)}" : "Hidden"}',
                  'Pending: ${viewModel.isFeesVisible ? "₹${pendingRevenue.toStringAsFixed(0)}" : "Hidden"}',
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 6),
              const SizedBox(width: 8),
              Expanded(child: Text(item)),
            ],
          ),
        )),
      ],
    );
  }

  Future<void> _showStudentHistoryWithFeedback(BuildContext context, Student student) async {
    final viewModel = Provider.of<StudentViewModel>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await viewModel.showHistory(student);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (!mounted) return;

      if (viewModel.studentHistory != null) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (dialogContext) => StudentHistoryDialog(
            history: viewModel.studentHistory!,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No payment history found for ${student.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading history: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showConfirmPaymentDialog(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (context) => ConfirmPaymentDialog(student: student),
    );
  }

  void _showConfirmUnpaidDialog(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (context) => ConfirmUnpaidDialog(student: student),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String studentId) {
    final student = Provider.of<StudentViewModel>(context, listen: false)
        .allStudents
        .firstWhere((s) => s.id == studentId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<StudentViewModel>(context, listen: false).deleteStudent(studentId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class HyperSensitivePageScrollPhysics extends PageScrollPhysics {
  const HyperSensitivePageScrollPhysics({super.parent});

  @override
  HyperSensitivePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return HyperSensitivePageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => 50.0;

  @override
  double get minFlingDistance => 8.0;

  @override
  Tolerance get tolerance => const Tolerance(
    velocity: 0.5,
    distance: 0.1,
  );

  @override
  double get dragStartDistanceMotionThreshold => 3.0;
}
