import 'package:internal_request_app/domain/enums/request_priority.dart';
import 'package:internal_request_app/domain/enums/request_status.dart';

class Request {
  final String id;
  final String serviceId;          
  final String requesterId;         
  final String description;         
  final RequestStatus status;       
  final int progress;               
  final String? approverId;         
  final String? executorId;         
  final RequestPriority? priority;  
  final DateTime? limitDate;      

  Request({
    required this.id,
    required this.serviceId,
    required this.requesterId,
    required this.description,
    required this.status,
    required this.progress,
    this.approverId,
    this.executorId,
    this.priority,
    this.limitDate,
  });
}
