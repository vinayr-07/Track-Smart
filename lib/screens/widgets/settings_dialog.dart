import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // ADDED: Missing import for DateFormat
import '../../viewmodels/student_viewmodel.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentViewModel>(
      builder: (context, viewModel, child) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('System'),
                value: 'System',
                groupValue: viewModel.themePreference,
                onChanged: (value) => viewModel.changeTheme(value!),
              ),
              RadioListTile<String>(
                title: const Text('Light'),
                value: 'Light',
                groupValue: viewModel.themePreference,
                onChanged: (value) => viewModel.changeTheme(value!),
              ),
              RadioListTile<String>(
                title: const Text('Dark'),
                value: 'Dark',
                groupValue: viewModel.themePreference,
                onChanged: (value) => viewModel.changeTheme(value!),
              ),
              const Divider(),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.backup,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                title: const Text('Create Backup'),
                subtitle: const Text('Save to Downloads/backups/TrackSmart/\nIncludes all students & payment history'),
                onTap: () => _exportData(context, viewModel),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restore,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                title: const Text('Restore Backup'),
                subtitle: const Text('Import from Downloads/backups/TrackSmart/\nReplaces all current data'),
                onTap: () => _importData(context, viewModel),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder_open,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                    size: 20,
                  ),
                ),
                title: const Text('View Backup Files'),
                subtitle: Text('Location: ${viewModel.getBackupFolderPath()}'),
                onTap: () => _viewBackupFiles(context, viewModel),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _exportData(BuildContext context, StudentViewModel viewModel) async {
    Navigator.pop(context);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating JSON backup...'),
            SizedBox(height: 8),
            Text(
              'Saving to Downloads/backups/TrackSmart/',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );

    try {
      final result = await viewModel.exportData();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        final isSuccess = !result.contains('Export failed');

        // Show result dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess
                      ? Colors.green
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(isSuccess ? 'Backup Created' : 'Export Failed'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (isSuccess) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.folder,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Find your backup in:\nDownloads/backups/TrackSmart/',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                const Text('Export Error'),
              ],
            ),
            content: Text('Unexpected error occurred:\n${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _importData(BuildContext context, StudentViewModel viewModel) async {
    Navigator.pop(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Restore Backup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will replace ALL current data with the backup data.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What will happen:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('• All current students will be deleted'),
                  Text('• All current payment records will be deleted'),
                  Text('• Backup data will be imported'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Look for backup files in: ${viewModel.getBackupFolderPath()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Select Backup File'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Selecting and importing JSON backup...'),
              SizedBox(height: 8),
              Text(
                'Navigate to Downloads/backups/TrackSmart/',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      );
    }

    try {
      final result = await viewModel.importData();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        final isSuccess = !result.contains('Import Failed!');

        // Show result dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess
                      ? Colors.green
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(isSuccess ? 'Backup Restored' : 'Import Failed'),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                result,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                const Text('Import Error'),
              ],
            ),
            content: Text('Unexpected error occurred:\n${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _viewBackupFiles(BuildContext context, StudentViewModel viewModel) async {
    Navigator.pop(context);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Scanning backup files...'),
          ],
        ),
      ),
    );

    try {
      final backupFiles = await viewModel.getAvailableBackupFiles();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show backup files list
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.folder_open),
                SizedBox(width: 8),
                Text('Available Backup Files'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location: ${viewModel.getBackupFolderPath()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: backupFiles.isEmpty
                        ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_off, size: 48),
                          SizedBox(height: 8),
                          Text('No backup files found'),
                          Text(
                            'Create a backup first',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      itemCount: backupFiles.length,
                      itemBuilder: (context, index) {
                        final fileName = backupFiles[index];
                        final dateMatch = RegExp(r'(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2})').firstMatch(fileName);
                        String displayDate = 'Unknown date';

                        if (dateMatch != null) {
                          try {
                            final dateStr = dateMatch.group(1)!.replaceAll('_', ' ').replaceAll('-', ':');
                            final parsedDate = DateFormat('yyyy:MM:dd HH:mm:ss').parse(dateStr);
                            displayDate = DateFormat('dd MMM yyyy, HH:mm').format(parsedDate);
                          } catch (e) {
                            // Keep default display date
                          }
                        }

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(
                              fileName,
                              style: const TextStyle(fontSize: 12),
                            ),
                            subtitle: Text(displayDate),
                            dense: true,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning backup files: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
