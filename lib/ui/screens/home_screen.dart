import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/station_model.dart';
import '../../providers/radio_provider.dart';
import '../../services/share_service.dart';
import '../widgets/ad_space.dart';
import '../widgets/mini_player.dart';
import '../widgets/share_origin.dart';
import '../widgets/station_card.dart';
import '../widgets/station_logo.dart';

/// Pantalla principal con buscador, filtros por región y género, emisoras
/// destacadas y pestaña de Favoritos.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.radio_rounded),
              SizedBox(width: 8),
              Flexible(child: Text(AppConstants.appName)),
            ],
          ),
          actions: const [_ThemeMenuButton(), _ShareAppButton()],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.cell_tower_rounded), text: 'Emisoras'),
              Tab(icon: Icon(Icons.favorite_rounded), text: 'Favoritos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_StationsTab(), _FavoritesTab()],
        ),
        bottomNavigationBar: const _BottomBar(),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Barra superior
// -----------------------------------------------------------------------------

class _ThemeMenuButton extends StatelessWidget {
  const _ThemeMenuButton();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RadioProvider>();
    final icon = switch (provider.themeMode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Tema',
      icon: Icon(icon),
      initialValue: provider.themeMode,
      onSelected: provider.setThemeMode,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ThemeMode.system,
          child: ListTile(
            leading: Icon(Icons.brightness_auto_outlined),
            title: Text('Según el sistema'),
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: ListTile(
            leading: Icon(Icons.light_mode_outlined),
            title: Text('Modo claro'),
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: ListTile(
            leading: Icon(Icons.dark_mode_outlined),
            title: Text('Modo oscuro'),
          ),
        ),
      ],
    );
  }
}

class _ShareAppButton extends StatelessWidget {
  const _ShareAppButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Compartir la app',
      icon: const Icon(Icons.share_outlined),
      onPressed: () => context
          .read<ShareService>()
          .shareApp(origin: shareOriginOf(context)),
    );
  }
}

// -----------------------------------------------------------------------------
// Pestaña "Emisoras"
// -----------------------------------------------------------------------------

class _StationsTab extends StatelessWidget {
  const _StationsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RadioProvider>();

    if (!provider.hasStations) {
      return provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _MessageView(
              icon: Icons.wifi_off_rounded,
              title: 'No se pudieron cargar las emisoras',
              message: 'Revisa tu conexión a internet e inténtalo de nuevo.',
              actionLabel: 'Reintentar',
              onAction: provider.loadStations,
            );
    }

    final results = provider.filteredStations;
    final showFeatured =
        !provider.hasActiveFilters && provider.featuredStations.isNotEmpty;

    return RefreshIndicator(
      onRefresh: provider.loadStations,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          const SliverToBoxAdapter(child: _SearchField()),
          const SliverToBoxAdapter(child: _Filters()),
          if (!provider.radioBrowserAvailable)
            const SliverToBoxAdapter(child: _OfflineNotice()),
          if (showFeatured) ...[
            const SliverToBoxAdapter(child: _SectionTitle('Destacadas')),
            SliverToBoxAdapter(
              child: _FeaturedCarousel(stations: provider.featuredStations),
            ),
          ],
          SliverToBoxAdapter(
            child: _SectionTitle(
              provider.hasActiveFilters
                  ? '${results.length} ${results.length == 1 ? 'emisora' : 'emisoras'}'
                  : 'Todas las emisoras',
            ),
          ),
          if (results.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _MessageView(
                icon: Icons.search_off_rounded,
                title: 'Sin resultados',
                message: 'No hay emisoras que coincidan con tu búsqueda.',
                actionLabel: 'Limpiar filtros',
                onAction: provider.clearFilters,
              ),
            )
          else
            SliverList.builder(
              itemCount: results.length,
              itemBuilder: (context, index) =>
                  StationCard(station: results[index]),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: context.read<RadioProvider>().query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RadioProvider>();
    // Si se limpian los filtros desde otro botón, se vacía también el campo
    // (después del frame, para no modificar el campo durante el build).
    final query = context.select<RadioProvider, String>((p) => p.query);
    if (query.isEmpty && _controller.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.read<RadioProvider>().query.isEmpty) {
          _controller.clear();
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SearchBar(
        controller: _controller,
        hintText: 'Buscar por nombre o frecuencia',
        leading: const Icon(Icons.search_rounded),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: provider.setQuery,
        trailing: [
          if (query.isNotEmpty)
            IconButton(
              tooltip: 'Borrar búsqueda',
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _controller.clear();
                provider.setQuery('');
              },
            ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RadioProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChipRow(
          icon: Icons.place_outlined,
          options: provider.regions,
          selected: provider.selectedRegion,
          onSelected: provider.setRegion,
          allLabel: 'Todo el Perú',
        ),
        _ChipRow(
          icon: Icons.music_note_outlined,
          options: provider.genres,
          selected: provider.selectedGenre,
          onSelected: provider.setGenre,
          allLabel: 'Todos los géneros',
        ),
      ],
    );
  }
}

/// Fila desplazable de chips de un solo valor con opción "Todos".
class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.icon,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.allLabel,
  });

  final IconData icon;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          _chip(allLabel, selected == null, () => onSelected(selected)),
          for (final option in options)
            _chip(option, option == selected, () => onSelected(option)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _FeaturedCarousel extends StatelessWidget {
  const _FeaturedCarousel({required this.stations});

  final List<Station> stations;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RadioProvider>();
    final theme = Theme.of(context);
    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stations.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final station = stations[index];
          return SizedBox(
            width: 92,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => provider.play(station),
              child: Column(
                children: [
                  StationLogo(station: station, size: 88, borderRadius: 20),
                  const SizedBox(height: 6),
                  Text(
                    station.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge,
                  ),
                  Text(
                    station.frecuencia,
                    maxLines: 1,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: scheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mostrando solo el catálogo principal. Desliza hacia abajo '
                  'para volver a cargar todas las emisoras.',
                  style: TextStyle(color: scheme.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pestaña "Favoritos"
// -----------------------------------------------------------------------------

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<RadioProvider>().favoriteStations;
    if (favorites.isEmpty) {
      return const _MessageView(
        icon: Icons.favorite_border_rounded,
        title: 'Aún no tienes favoritas',
        message: 'Toca el corazón de una emisora para tenerla siempre a mano.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: favorites.length,
      itemBuilder: (context, index) => StationCard(station: favorites[index]),
    );
  }
}

// -----------------------------------------------------------------------------
// Comunes
// -----------------------------------------------------------------------------

/// Mini reproductor y espacio publicitario anclados abajo.
class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    final hasStation =
        context.select<RadioProvider, bool>((p) => p.currentStation != null);
    if (!hasStation && !AppConstants.enableAds) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: const SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [MiniPlayer(), AdSpace()],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
