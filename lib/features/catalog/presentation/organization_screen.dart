import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/state/live_query.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/rating_badge.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_title.dart';
import '../../favorites/data/favorites_repository.dart';
import '../../favorites/presentation/favorite_button.dart';
import '../../reviews/data/review_repository.dart';
import '../../reviews/domain/rating_summary.dart';
import '../../reviews/domain/review.dart';
import '../../reviews/presentation/review_widgets.dart';
import '../data/catalog_repository.dart';
import '../domain/organization.dart';
import '../domain/service.dart';
import 'photo_gallery_screen.dart';
import 'service_category_style.dart';
import 'widgets/business_photo_view.dart';

class OrganizationDetails {
  const OrganizationDetails({
    required this.organization,
    required this.photos,
    required this.services,
    required this.specialists,
    required this.reviews,
    required this.isFavorite,
  });

  final Organization organization;
  final List<BusinessPhoto> photos;
  final List<Service> services;
  final List<Specialist> specialists;
  final List<Review> reviews;
  final bool isFavorite;
}

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({
    super.key,
    required this.organizationId,
    required this.catalog,
    required this.reviews,
    required this.favorites,
    required this.onServiceSelected,
    required this.onOpenReviews,
    this.canFavorite = true,
  });

  static const minReviewsForSpecialistRating = 3;

  final String organizationId;
  final CatalogRepository catalog;
  final ReviewRepository reviews;
  final FavoritesRepository favorites;
  final ValueChanged<Service> onServiceSelected;
  final ValueChanged<Organization> onOpenReviews;

  final bool canFavorite;

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  late final _query = LiveQuery<OrganizationDetails>(
    _load,
    refreshOn: Listenable.merge([
      widget.catalog.changes,
      widget.reviews.changes,
      widget.favorites.changes,
    ]),
  )..load();
  final _photoPage = ValueNotifier(0);
  int _burst = 0;

  Future<OrganizationDetails> _load() async {
    final id = widget.organizationId;
    return OrganizationDetails(
      organization: await widget.catalog.fetchOrganization(id),
      photos: await widget.catalog.fetchPhotos(id),
      services: await widget.catalog.fetchServices(organizationId: id),
      specialists: await widget.catalog.fetchSpecialists(id),
      reviews: await widget.reviews.fetchOrganizationReviews(id),
      isFavorite: (await widget.favorites.fetchFavoriteIds()).contains(id),
    );
  }

  @override
  void dispose() {
    _query.dispose();
    _photoPage.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(OrganizationDetails details) async {
    final messenger = ScaffoldMessenger.of(context);
    final isFavorite = await widget.favorites.toggle(details.organization.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isFavorite ? AppStrings.favoriteAdded : AppStrings.favoriteRemoved,
          ),
        ),
      );
  }

  void _onDoubleTap(OrganizationDetails details) {
    if (!widget.canFavorite) return;
    HapticFeedback.lightImpact();
    setState(() => _burst++);
    if (!details.isFavorite) _toggleFavorite(details);
  }

  void _openGallery(OrganizationDetails details, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => PhotoGalleryScreen(
          organizationName: details.organization.name,
          category: details.organization.category,
          photos: details.photos,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _query,
        builder: (context, _) {
          final details = _query.data;
          if (details == null) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: _query.error == null
                    ? const CircularProgressIndicator()
                    : EmptyState(
                        icon: Icons.cloud_off,
                        title: AppStrings.organizationLoadError,
                        message: AppStrings.bookingsLoadErrorMessage,
                        actionLabel: AppStrings.bookingRetry,
                        onAction: _query.load,
                      ),
              ),
            );
          }
          return _buildContent(context, details);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, OrganizationDetails details) {
    final theme = Theme.of(context);
    final organization = details.organization;
    final summary = RatingSummary.of(details.reviews);
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = responsiveGutter(constraints.maxWidth);
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 260,
              title: Text(organization.name),
              actions: [
                if (widget.canFavorite)
                  FavoriteButton(
                    isFavorite: details.isFavorite,
                    onPressed: () => _toggleFavorite(details),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _Gallery(
                  details: details,
                  page: _photoPage,
                  burst: _burst,
                  showBurst: widget.canFavorite,
                  onTap: (index) => _openGallery(details, index),
                  onDoubleTap: () => _onDoubleTap(details),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, AppSpacing.l, gutter, 0),
              sliver: SliverList.list(
                children: [
                  Text(organization.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    organization.category.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  InkWell(
                    onTap: () => widget.onOpenReviews(organization),
                    borderRadius: BorderRadius.circular(AppRadii.s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.s,
                      ),
                      child: RatingBadge(summary: summary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    organization.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  InfoRow(
                    icon: Icons.place_outlined,
                    label: AppStrings.organizationAddress,
                    value: organization.address,
                  ),
                  InfoRow(
                    icon: Icons.phone_outlined,
                    label: AppStrings.organizationPhone,
                    value: organization.phone,
                  ),
                  const _SectionHeader(AppStrings.organizationServices),
                  if (details.services.isEmpty)
                    const Text(AppStrings.organizationNoServices)
                  else
                    for (final service in details.services)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s),
                        child: _PriceListItem(
                          service: service,
                          onTap: () => widget.onServiceSelected(service),
                        ),
                      ),
                  const _SectionHeader(AppStrings.organizationSpecialists),
                  for (final specialist in details.specialists)
                    _SpecialistRow(
                      specialist: specialist,
                      summary: RatingSummary.of(
                        details.reviews.where(
                          (r) => r.specialistId == specialist.id,
                        ),
                      ),
                    ),
                  const _SectionHeader(AppStrings.organizationReviews),
                  if (summary.isEmpty)
                    Text(
                      AppStrings.reviewsEmptyMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else ...[
                    RatingDistribution(summary: summary),
                    const SizedBox(height: AppSpacing.m),
                    for (final review in details.reviews.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.m),
                        child: ReviewTile(review: review),
                      ),
                    OutlinedButton(
                      onPressed: () => widget.onOpenReviews(organization),
                      child: Text(
                        '${AppStrings.organizationAllReviews} '
                        '(${summary.count})',
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => SectionTitle(
    text,
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.s),
  );
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.details,
    required this.page,
    required this.burst,
    required this.showBurst,
    required this.onTap,
    required this.onDoubleTap,
  });

  final OrganizationDetails details;
  final ValueNotifier<int> page;
  final int burst;
  final bool showBurst;
  final ValueChanged<int> onTap;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final photos = details.photos;
    final organization = details.organization;
    if (photos.isEmpty) {
      return BusinessPhotoView(photo: null, category: organization.category);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: photos.length,
          onPageChanged: (index) => page.value = index,
          itemBuilder: (context, index) => Semantics(
            button: true,
            label: AppStrings.photoLabel(organization.name, index + 1),
            hint: AppStrings.favoriteDoubleTapHint,
            child: GestureDetector(
              onTap: () => onTap(index),
              onDoubleTap: onDoubleTap,
              child: BusinessPhotoView(
                photo: photos[index],
                category: organization.category,
                decodeWidth: 480,
              ),
            ),
          ),
        ),
        if (showBurst) FavoriteBurst(trigger: burst),
        if (photos.length > 1)
          Positioned(
            right: AppSpacing.l,
            bottom: AppSpacing.l,
            child: ValueListenableBuilder(
              valueListenable: page,
              builder: (context, index, _) => DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(AppRadii.s),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    AppStrings.galleryPosition(index + 1, photos.length),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PriceListItem extends StatelessWidget {
  const _PriceListItem({required this.service, required this.onTap});

  final Service service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final price = service.hasPriceOptions
        ? AppStrings.priceFrom(Formatters.price(service.minPriceKzt))
        : Formatters.price(service.priceKzt);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service.title,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    price,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              Text(Formatters.duration(service.duration), style: muted),
              for (final option in service.priceOptions)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(child: Text(option.label, style: muted)),
                      Text(Formatters.price(option.priceKzt), style: muted),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecialistRow extends StatelessWidget {
  const _SpecialistRow({required this.specialist, required this.summary});

  final Specialist specialist;
  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final average = summary.average;
    final hasRating =
        average != null &&
        summary.count >= OrganizationScreen.minReviewsForSpecialistRating;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        foregroundColor: theme.colorScheme.onSecondaryContainer,
        child: Text(Formatters.initials(specialist.name)),
      ),
      title: Text(specialist.name),
      subtitle: Text(
        '${specialist.role} · '
        '${hasRating ? AppStrings.specialistRating(formatRating(average), summary.count) : AppStrings.specialistFewReviews}',
      ),
    );
  }
}
