import 'package:flutter/foundation.dart';
import '../models/agent_response.dart';
import '../services/agent_service.dart';

enum GenerationStatus { idle, loading, success, error }

enum PipelineStep { retrieve, generate, check }

class AgentProvider extends ChangeNotifier {
  GenerationStatus _status = GenerationStatus.idle;
  AgentResponse? _response;
  String? _errorMessage;
  PipelineStep? _currentStep;
  String? _activeThreadId;

  GenerationStatus get status => _status;
  AgentResponse? get response => _response;
  String? get errorMessage => _errorMessage;
  PipelineStep? get currentStep => _currentStep;
  bool get isLoading => _status == GenerationStatus.loading;

  Future<void> generate(String question) async {
    _status = GenerationStatus.loading;
    _response = null;
    _errorMessage = null;
    _currentStep = PipelineStep.retrieve;
    notifyListeners();

    // Simulate pipeline steps for UX (real steps happen inside the backend)
    await _advancePipeline();

    try {
      final result = await AgentService.generate(
        question: question,
        threadId: _activeThreadId,
      );
      _activeThreadId = result.threadId;
      _response = result;
      _status = GenerationStatus.success;
      _currentStep = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = GenerationStatus.error;
      _currentStep = null;
    }

    notifyListeners();
  }

  /// Simulates advancing through pipeline steps visually while we wait.
  Future<void> _advancePipeline() async {
    // After 1s show "generate", after 2s show "check" — then the real answer arrives.
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (_status == GenerationStatus.loading) {
        _currentStep = PipelineStep.generate;
        notifyListeners();
      }
    });
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (_status == GenerationStatus.loading) {
        _currentStep = PipelineStep.check;
        notifyListeners();
      }
    });
  }

  void reset() {
    _status = GenerationStatus.idle;
    _response = null;
    _errorMessage = null;
    _currentStep = null;
    _activeThreadId = null;
    notifyListeners();
  }

  void newThread() {
    _activeThreadId = null;
    reset();
  }
}
