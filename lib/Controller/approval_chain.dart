import 'package:get/get.dart';
import 'package:stock_management/Model/lookup_models.dart';
import 'package:stock_management/Model/request_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/request_service.dart';

/// One row of the "Approvers & Verification" section: who, and in which role.
class ApproverDraft {
  ApproverDraft({LookupOption? role}) {
    this.role.value = role;
  }

  final reviewer = Rxn<LookupOption>();
  final role = Rxn<LookupOption>();
}

/// The approval chain a requester builds for any request (new product, stock
class ApprovalChain {
  ApprovalChain({RequestService? requests, this.approverRoles}) : _requests = requests ?? RequestService();

  final RequestService _requests;

  /// When set, only people holding one of these roles can be picked as an
  /// Approver (e.g. a Manager's new product must go to an Admin or Super Admin).
  final Set<String>? approverRoles;

  bool _mayApprove(ApproverCandidate c) =>
      c.canApprove && (approverRoles == null || c.roles.any(approverRoles!.contains));

  static const _certifierCode = 'CERTIFIER';
  static const _approverCode = 'APPROVER';

  final candidates = <ApproverCandidate>[].obs;
  final isLoadingCandidates = false.obs;
  final drafts = <ApproverDraft>[].obs;

  /// Set when loading the people fails; the owner may surface it.
  final loadError = RxnString();

  List<LookupOption> get roleOptions => [
        LookupOption(id: _certifierCode, code: _certifierCode, name: ApproverRole.certifier.label),
        LookupOption(id: _approverCode, code: _approverCode, name: ApproverRole.approver.label),
      ];

  LookupOption get _defaultRole => roleOptions[1];

  /// Starts with one empty Approver row and loads the people to choose from.
  Future<void> start() async {
    if (drafts.isEmpty) drafts.add(ApproverDraft(role: _defaultRole));
    await loadCandidates();
  }

  Future<void> loadCandidates() async {
    isLoadingCandidates.value = true;
    loadError.value = null;
    try {
      candidates.assignAll(await _requests.approverCandidates());
    } on ApiException catch (e) {
      loadError.value = e.message;
    } finally {
      isLoadingCandidates.value = false;
    }
  }

  void addRow() => drafts.add(ApproverDraft(role: _defaultRole));

  void removeRow(int index) {
    if (index < 0 || index >= drafts.length) return;
    drafts.removeAt(index);
  }

  ApproverCandidate? _candidateFor(LookupOption? option) {
    if (option == null) return null;
    for (final c in candidates) {
      if (c.id == option.id) return c;
    }
    return null;
  }

  /// People shown in row [index]'s picker: nobody already used in another
  /// row, and — for the Approver role — only ADMIN / MANAGER / SUPER_ADMIN.
  List<LookupOption> reviewerOptionsFor(int index) {
    if (index < 0 || index >= drafts.length) return const [];
    final draft = drafts[index];
    final usedElsewhere = <String>{
      for (var i = 0; i < drafts.length; i++)
        if (i != index && drafts[i].reviewer.value != null) drafts[i].reviewer.value!.id,
    };
    final onlyApprovers = draft.role.value?.code == _approverCode;
    return [
      for (final c in candidates)
        if (!usedElsewhere.contains(c.id) && (!onlyApprovers || _mayApprove(c)))
          LookupOption(id: c.id, code: c.staffId, name: c.label),
    ];
  }

  void setRole(ApproverDraft draft, LookupOption? role) {
    draft.role.value = role;
    // Switching to Approver: a reviewer who may not approve has to be re-picked.
    if (role?.code == _approverCode) {
      final candidate = _candidateFor(draft.reviewer.value);
      if (candidate != null && !_mayApprove(candidate)) draft.reviewer.value = null;
    }
  }

  /// Rules the server also enforces, caught here so the person sees them
  /// next to the form instead of as a failed request. Null when fine.
  String? get error {
    if (drafts.isEmpty) return 'validation_approver_required'.tr;
    if (drafts.last.role.value?.code != _approverCode) return 'validation_last_approver'.tr;
    return null;
  }

  /// `[{userId, actionType}]` in step order, as `POST /requests` expects.
  List<Map<String, dynamic>> toPayload() => [
        for (final d in drafts) {'userId': d.reviewer.value!.id, 'actionType': d.role.value!.code},
      ];
}
