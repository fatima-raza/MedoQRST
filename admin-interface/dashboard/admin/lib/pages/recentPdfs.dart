import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart';

class RecentPdfWidget extends StatefulWidget {
  final List<File> recentPdfs;
  final String pdfDirectoryPath;

  const RecentPdfWidget({
    Key? key,
    required this.recentPdfs,
    required this.pdfDirectoryPath,
  }) : super(key: key);

  @override
  _RecentPdfWidgetState createState() => _RecentPdfWidgetState();
}

class _RecentPdfWidgetState extends State<RecentPdfWidget> {
  List<File> validPdfs = [];

  @override
  void initState() {
    super.initState();
    _updateRecentPdfs();
  }

  @override
  // void didUpdateWidget(covariant RecentPdfWidget oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (widget.recentPdfs != oldWidget.recentPdfs) {
  //     _updateRecentPdfs();
  //   }
  // }

  @override
  void didUpdateWidget(covariant RecentPdfWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update when recentPdfs OR pdfDirectoryPath changes
    if (widget.recentPdfs != oldWidget.recentPdfs ||
        widget.pdfDirectoryPath != oldWidget.pdfDirectoryPath) {
      _updateRecentPdfs();
    }
  }

//  void _updateRecentPdfs() {
//   DateTime threeDaysAgo = DateTime.now().subtract(Duration(days: 3));
//   final directory = Directory(widget.pdfDirectoryPath);
//   final allFiles = directory.listSync(); // Get all files

//   setState(() {
//     validPdfs = allFiles
//         .whereType<File>() // Only files (ignore folders)
//         .where((file) =>
//             file.path.endsWith('.pdf') && // Only PDFs
//             file.existsSync() &&
//             file.lastModifiedSync().isAfter(threeDaysAgo)) // Modified recently
//         .toList();
//   });
// }
  void _updateRecentPdfs() {
    DateTime threeDaysAgo = DateTime.now().subtract(Duration(days: 3));
    final directory = Directory(widget.pdfDirectoryPath);
    final allFiles = directory.listSync(); // Get all files

    print('Scanning directory: ${widget.pdfDirectoryPath}');
    print('Found total files: ${allFiles.length}');

    final filteredPdfs = allFiles
        .whereType<File>() // Only files (ignore folders)
        .where((file) =>
            file.path.endsWith('.pdf') &&
            file.existsSync() &&
            file.lastModifiedSync().isAfter(threeDaysAgo)) // Modified recently
        .toList();

    print('Filtered valid recent PDFs: ${filteredPdfs.length}');
    for (var file in filteredPdfs) {
      print('PDF: ${file.path} | Modified: ${file.lastModifiedSync()}');
    }

    setState(() {
      validPdfs = filteredPdfs;
    });
  }

  void _deletePdf(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Delete PDF"),
          content:
              Text("Are you sure you want to delete ${basename(file.path)}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel",
                  style: TextStyle(color: const Color(0xFF103783))),
            ),
            TextButton(
              onPressed: () {
                try {
                  file.deleteSync();
                  setState(() {
                    validPdfs.remove(file);
                  });
                  Navigator.pop(dialogContext);
                } catch (e) {
                  Navigator.pop(dialogContext);
                  showDialog(
                    context: context,
                    builder: (BuildContext errorContext) {
                      return AlertDialog(
                        title: Text("Error"),
                        content:
                            Text("Failed to delete ${basename(file.path)}."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(errorContext),
                            child: Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Text("Delete",
                  style: TextStyle(
                    color: const Color(0xFF103783),
                  )),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building RecentPdfWidget for directory: ${widget.pdfDirectoryPath}');
    return validPdfs.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Recently Generated",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: validPdfs.length,
                  itemBuilder: (context, index) {
                    File file = validPdfs[index];
                    String fileName = basename(file.path);
                    String formattedDate;
                    try {
                      formattedDate = DateFormat('dd-MM-yyyy | hh:mm a')
                          .format(file.lastModifiedSync());
                    } catch (e) {
                      formattedDate = "Unknown Date";
                    }

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: Icon(
                          Icons.picture_as_pdf,
                          color: Color(0xFF103783), // Deep blue color
                          size: 30,
                        ),
                        title: Text(
                          fileName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(" $formattedDate"),
                        onTap: () => OpenFilex.open(file.path),
                        trailing: Tooltip(
                          message: "Delete",
                          child: IconButton(
                            icon: Icon(Icons.delete, color: Color(0xFF103783)),
                            onPressed: () => _deletePdf(context, file),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // ListView.builder(
                //   itemCount: validPdfs.length,
                //   itemBuilder: (context, index) {
                //     File file = validPdfs[index];
                //     String fileName = basename(file.path);
                //     String formattedDate;
                //     try {
                //       formattedDate = DateFormat('dd-MM-yyyy | hh:mm a')
                //           .format(file.lastModifiedSync());
                //     } catch (e) {
                //       formattedDate = "Unknown Date";
                //     }

                //     return Card(
                //       margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                //       child: ListTile(
                //         title: Text(fileName,
                //             style: TextStyle(fontWeight: FontWeight.bold)),
                //         subtitle: Text(" $formattedDate"),
                //         onTap: () => OpenFilex.open(file.path),
                //         trailing: Tooltip(
                //           message: "Delete",
                //           child: IconButton(
                //             icon: Icon(Icons.delete,
                //                 color: const Color(0xFF103783)),
                //             onPressed: () => _deletePdf(context, file),
                //           ),
                //         ),
                //       ),
                //     );
                //   },
                // ),
              ),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "No Recent PDF",
                style: TextStyle(
                    color: const Color(0xFF103783),
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => OpenFilex.open(widget.pdfDirectoryPath),
                child: Text(
                  "Open Folder",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ],
          );
  }
}
