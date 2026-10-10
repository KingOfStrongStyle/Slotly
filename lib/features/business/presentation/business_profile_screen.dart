import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/state/live_query.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_title.dart';
import '../../../data/local/local_context.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/organization.dart';
import '../../catalog/presentation/widgets/business_photo_view.dart';
import '../data/business_repository.dart';
import '../data/photo_picker.dart';
import '../domain/business_rules.dart';

class _BusinessData {
  const _BusinessData(this.organization, this.photos);

  final Organization organization;
  final List<BusinessPhoto> photos;
}

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({
    super.key,
    required this.organizationId,
    required this.catalog,
    required this.business,
    required this.photoPicker,
    required this.settings,
  });

  final String organizationId;
  final CatalogRepository catalog;
  final BusinessRepository business;
  final PhotoPicker photoPicker;

  final List<Widget> settings;

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  late final _query = LiveQuery<_BusinessData>(
    () async => _BusinessData(
      await widget.catalog.fetchOrganization(widget.organizationId),
      await widget.catalog.fetchPhotos(widget.organizationId),
    ),
    refreshOn: widget.catalog.changes,
  )..load();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  Organization? _loaded;
  bool _showErrors = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _query.addListener(_fillForm);
  }

  @override
  void dispose() {
    _query
      ..removeListener(_fillForm)
      ..dispose();
    for (final controller in [_name, _description, _address, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _fillForm() {
    final organization = _query.data?.organization;
    if (organization == null || _loaded != null) return;
    _loaded = organization;
    _name.text = organization.name;
    _description.text = organization.description;
    _address.text = organization.address;
    _phone.text = organization.phone;
  }

  Organization? _draft() => _loaded?.copyWith(
    name: _name.text,
    description: _description.text,
    address: _address.text,
    phone: _phone.text,
  );

  Future<void> _save() async {
    final draft = _draft();
    if (draft == null) return;
    FocusScope.of(context).unfocus();
    if (BusinessRules.validateOrganization(draft).isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    await _busy(() async {
      _loaded = await widget.business.updateOrganization(draft);
      _snack(AppStrings.businessSaved);
    });
  }

  // Ян: при пяти фото пикер даже не открываем, сразу сообщение
  Future<void> _addPhoto() async {
    final path = await widget.photoPicker.pickImage();
    if (path == null) return;
    await _busy(() async {
      try {
        await widget.business.addPhoto(widget.organizationId, sourcePath: path);
        _snack(AppStrings.businessPhotoAdded);
      } on ValidationException<PhotoIssue> catch (error) {
        _snack(switch (error.issues.first) {
          PhotoIssue.limitReached => AppStrings.businessPhotoLimit,
          PhotoIssue.unsupportedFormat => AppStrings.businessPhotoFormat,
          PhotoIssue.fileTooLarge => AppStrings.businessPhotoTooLarge,
        });
      } on Exception {
        _snack(AppStrings.businessPhotoFailed);
      }
    });
  }

  Future<void> _removePhoto(BusinessPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.businessPhotoRemoveTitle),
        content: const Text(AppStrings.businessPhotoRemoveMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.reviewKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.reviewDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _busy(() async {
      await widget.business.removePhoto(photo.id);
      _snack(AppStrings.businessPhotoRemoved);
    });
  }

  Future<void> _busy(Future<void> Function() action) async {
    setState(() => _isBusy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _query,
      builder: (context, _) {
        final data = _query.data;
        return LayoutBuilder(
          builder: (context, constraints) {
            final gutter = responsiveGutter(constraints.maxWidth);
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                const SliverAppBar(
                  pinned: true,
                  title: Text(AppStrings.businessTitle),
                ),
                if (data == null)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      0,
                      gutter,
                      AppSpacing.xl,
                    ),
                    sliver: SliverList.list(
                      children: [
                        ..._profileForm(context),
                        ..._photos(context, data),
                        const SectionTitle(AppStrings.businessSettingsSection),
                        ...widget.settings,
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _profileForm(BuildContext context) {
    final draft = _draft();
    final issues = _showErrors && draft != null
        ? BusinessRules.validateOrganization(draft)
        : const <OrganizationIssue>[];
    String? error(OrganizationIssue issue, String message) =>
        issues.contains(issue) ? message : null;
    void changed(String _) {
      if (_showErrors) setState(() {});
    }

    return [
      const SectionTitle(
        AppStrings.businessProfileSection,
        padding: EdgeInsets.only(top: AppSpacing.s, bottom: AppSpacing.s),
      ),
      TextField(
        controller: _name,
        onChanged: changed,
        decoration: InputDecoration(
          labelText: AppStrings.businessFieldName,
          errorText: error(
            OrganizationIssue.nameLength,
            AppStrings.businessNameLength,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.m),
      TextField(
        controller: _description,
        minLines: 2,
        maxLines: 5,
        onChanged: changed,
        decoration: InputDecoration(
          labelText: AppStrings.businessFieldDescription,
          errorText: error(
            OrganizationIssue.descriptionTooLong,
            AppStrings.businessDescriptionTooLong,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.m),
      TextField(
        controller: _address,
        onChanged: changed,
        decoration: InputDecoration(
          labelText: AppStrings.businessFieldAddress,
          errorText: error(
            OrganizationIssue.addressEmpty,
            AppStrings.businessAddressEmpty,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.m),
      TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        onChanged: changed,
        decoration: InputDecoration(
          labelText: AppStrings.businessFieldPhone,
          errorText: error(
            OrganizationIssue.phoneInvalid,
            AppStrings.businessPhoneInvalid,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.m),
      FilledButton(
        onPressed: _isBusy ? null : _save,
        child: const Text(AppStrings.businessSave),
      ),
    ];
  }

  List<Widget> _photos(BuildContext context, _BusinessData data) {
    final theme = Theme.of(context);
    final photos = data.photos;
    final canAdd = photos.length < Organization.maxPhotos;
    return [
      const SectionTitle(
        AppStrings.businessPhotosSection,
        padding: EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.xs),
      ),
      Text(
        AppStrings.businessPhotosCount(photos.length, Organization.maxPhotos),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppSpacing.m),
      for (final (index, photo) in photos.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.s),
                child: SizedBox(
                  width: 96,
                  height: 64,
                  child: Semantics(
                    label: AppStrings.photoLabel(
                      data.organization.name,
                      index + 1,
                    ),
                    child: BusinessPhotoView(
                      photo: photo,
                      category: data.organization.category,
                      decodeWidth: 96,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: AppStrings.businessPhotoMoveLeft,
                icon: const Icon(Icons.arrow_upward),
                onPressed: index == 0 || _isBusy
                    ? null
                    : () => widget.business.movePhoto(photo.id, index - 1),
              ),
              IconButton(
                tooltip: AppStrings.businessPhotoMoveRight,
                icon: const Icon(Icons.arrow_downward),
                onPressed: index == photos.length - 1 || _isBusy
                    ? null
                    : () => widget.business.movePhoto(photo.id, index + 1),
              ),
              IconButton(
                tooltip: AppStrings.businessPhotoRemove,
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                onPressed: _isBusy ? null : () => _removePhoto(photo),
              ),
            ],
          ),
        ),
      OutlinedButton.icon(
        onPressed: _isBusy
            ? null
            : canAdd
            ? _addPhoto
            : () => _snack(AppStrings.businessPhotoLimit),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text(AppStrings.businessPhotoAdd),
      ),
    ];
  }
}
