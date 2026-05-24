import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/organization.dart';
import '../../domain/repositories/partner_repository.dart';

part 'partner_event.dart';
part 'partner_state.dart';

@injectable
class PartnerBloc extends Bloc<PartnerEvent, PartnerState> {
  final PartnerRepository _partnerRepository;

  PartnerBloc(this._partnerRepository) : super(PartnerInitial()) {
    on<PartnerLoadDashboard>(_onLoadDashboard);
    on<PartnerLoadOrganization>(_onLoadOrganization);
    on<PartnerLoadOrganizationStats>(_onLoadOrganizationStats);
    on<PartnerLoadBeneficiaries>(_onLoadBeneficiaries);
    on<PartnerLoadMoreBeneficiaries>(_onLoadMoreBeneficiaries);
    on<PartnerCreateOrganization>(_onCreateOrganization);
    on<PartnerCreateBeneficiary>(_onCreateBeneficiary);
    on<PartnerUpdateBeneficiary>(_onUpdateBeneficiary);
    on<PartnerDeleteBeneficiary>(_onDeleteBeneficiary);
  }

  String? _currentOrganizationId;
  String? _currentStatusFilter;

  Future<void> _onLoadDashboard(
    PartnerLoadDashboard event,
    Emitter<PartnerState> emit,
  ) async {
    emit(PartnerLoading());
    _currentOrganizationId = event.organizationId;

    try {
      final results = await Future.wait([
        _partnerRepository.getOrganization(event.organizationId),
        _partnerRepository.getOrganizationWithStats(event.organizationId),
        _partnerRepository.listBeneficiaries(
          organizationId: event.organizationId,
          page: 1,
        ),
      ]);

      emit(PartnerDashboardLoaded(
        organization: results[0] as Organization,
        stats: results[1] as OrganizationWithStats,
        beneficiaries: (results[2] as PaginatedBeneficiaries).beneficiaries,
        total: (results[2] as PaginatedBeneficiaries).total,
        hasMore: (results[2] as PaginatedBeneficiaries).hasMore,
      ));
    } catch (e) {
      emit(PartnerError(e.toString()));
    }
  }

  Future<void> _onLoadOrganization(
    PartnerLoadOrganization event,
    Emitter<PartnerState> emit,
  ) async {
    emit(PartnerLoading());
    _currentOrganizationId = event.organizationId;

    try {
      final organization = await _partnerRepository.getOrganization(event.organizationId);
      final stats = await _partnerRepository.getOrganizationWithStats(event.organizationId);

      emit(PartnerOrganizationLoaded(
        organization: organization,
        stats: stats,
      ));
    } catch (e) {
      emit(PartnerError(e.toString()));
    }
  }

  Future<void> _onLoadOrganizationStats(
    PartnerLoadOrganizationStats event,
    Emitter<PartnerState> emit,
  ) async {
    try {
      final stats = await _partnerRepository.getOrganizationWithStats(event.organizationId);

      if (state is PartnerOrganizationLoaded) {
        emit(PartnerOrganizationLoaded(
          organization: (state as PartnerOrganizationLoaded).organization,
          stats: stats,
        ));
      }
    } catch (e) {
      emit(PartnerError(e.toString()));
    }
  }

  Future<void> _onLoadBeneficiaries(
    PartnerLoadBeneficiaries event,
    Emitter<PartnerState> emit,
  ) async {
    emit(PartnerLoading());
    _currentOrganizationId = event.organizationId;
    _currentStatusFilter = event.status;

    try {
      final result = await _partnerRepository.listBeneficiaries(
        organizationId: event.organizationId,
        page: event.page,
        status: event.status,
      );

      emit(PartnerBeneficiariesLoaded(
        beneficiaries: result.beneficiaries,
        total: result.total,
        page: result.page,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      emit(PartnerError(e.toString()));
    }
  }

  Future<void> _onLoadMoreBeneficiaries(
    PartnerLoadMoreBeneficiaries event,
    Emitter<PartnerState> emit,
  ) async {
    if (state is! PartnerDashboardLoaded && state is! PartnerBeneficiariesLoaded) return;

    bool hasMore = false;
    bool isLoadingMore = false;
    if (state is PartnerDashboardLoaded) {
      hasMore = (state as PartnerDashboardLoaded).hasMore;
      isLoadingMore = (state as PartnerDashboardLoaded).isLoadingMore;
    } else {
      hasMore = (state as PartnerBeneficiariesLoaded).hasMore;
      isLoadingMore = (state as PartnerBeneficiariesLoaded).isLoadingMore;
    }
    if (!hasMore || isLoadingMore) return;

    int currentPage = 1;
    if (state is PartnerDashboardLoaded) {
      final s = state as PartnerDashboardLoaded;
      emit(s.copyWith(isLoadingMore: true));
      currentPage = s.page;
    } else {
      final s = state as PartnerBeneficiariesLoaded;
      emit(s.copyWith(isLoadingMore: true));
      currentPage = s.page;
    }

    try {
      final result = await _partnerRepository.listBeneficiaries(
        organizationId: _currentOrganizationId!,
        page: currentPage + 1,
        status: _currentStatusFilter,
      );

      if (state is PartnerDashboardLoaded) {
        final s = state as PartnerDashboardLoaded;
        emit(PartnerDashboardLoaded(
          organization: s.organization,
          stats: s.stats,
          beneficiaries: [...s.beneficiaries, ...result.beneficiaries],
          total: result.total,
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ));
      } else {
        final s = state as PartnerBeneficiariesLoaded;
        emit(PartnerBeneficiariesLoaded(
          beneficiaries: [...s.beneficiaries, ...result.beneficiaries],
          total: result.total,
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ));
      }
    } catch (e) {
      emit(PartnerError(e.toString()));
    }
  }

  Future<void> _onCreateOrganization(
    PartnerCreateOrganization event,
    Emitter<PartnerState> emit,
  ) async {
    emit(PartnerLoading());

    try {
      final organization = await _partnerRepository.createOrganization(
        name: event.name,
        type: event.type,
        description: event.description,
        contactEmail: event.contactEmail,
        contactPhone: event.contactPhone,
        contactPerson: event.contactPerson,
        address: event.address,
        city: event.city,
        country: event.country,
      );

      emit(PartnerOrganizationCreated(organization));
    } catch (e) {
      emit(PartnerError(e.toString()));
    }
  }

  Future<void> _onCreateBeneficiary(
    PartnerCreateBeneficiary event,
    Emitter<PartnerState> emit,
  ) async {
    emit(PartnerLoading());

    try {
      final beneficiary = await _partnerRepository.createBeneficiary(
        organizationId: event.organizationId,
        firstName: event.firstName,
        lastName: event.lastName,
        dateOfBirth: event.dateOfBirth,
        gender: event.gender,
        placeOfBirth: event.placeOfBirth,
        fatherName: event.fatherName,
        motherName: event.motherName,
        guardianName: event.guardianName,
        guardianPhone: event.guardianPhone,
        guardianRelationship: event.guardianRelationship,
        address: event.address,
        city: event.city,
        country: event.country,
        photoUrl: event.photoUrl,
        notes: event.notes,
      );

      emit(PartnerBeneficiaryCreated(beneficiary));
    } catch (e) {
      emit(PartnerError(e.toString()));
    }
  }

  Future<void> _onUpdateBeneficiary(
    PartnerUpdateBeneficiary event,
    Emitter<PartnerState> emit,
  ) async {
    emit(PartnerLoading());

    try {
      await _partnerRepository.updateBeneficiary(event.beneficiaryId, event.data);

      if (_currentOrganizationId != null) {
        add(PartnerLoadDashboard(_currentOrganizationId!));
      }
    } catch (e) {
      emit(PartnerError(e.toString()));
    }
  }

  Future<void> _onDeleteBeneficiary(
    PartnerDeleteBeneficiary event,
    Emitter<PartnerState> emit,
  ) async {
    emit(PartnerLoading());

    try {
      await _partnerRepository.deleteBeneficiary(event.beneficiaryId);

      if (_currentOrganizationId != null) {
        add(PartnerLoadDashboard(_currentOrganizationId!));
      }
    } catch (e) {
      emit(PartnerError(e.toString()));
    }
  }
}