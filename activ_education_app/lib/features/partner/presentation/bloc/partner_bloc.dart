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
    if (state is! PartnerBeneficiariesLoaded) return;

    final currentState = state as PartnerBeneficiariesLoaded;
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final result = await _partnerRepository.listBeneficiaries(
        organizationId: _currentOrganizationId!,
        page: currentState.page + 1,
        status: _currentStatusFilter,
      );

      emit(PartnerBeneficiariesLoaded(
        beneficiaries: [...currentState.beneficiaries, ...result.beneficiaries],
        total: result.total,
        page: result.page,
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
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
        add(PartnerLoadBeneficiaries(organizationId: _currentOrganizationId!));
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
      await _partnerRepository.updateBeneficiary(
        event.beneficiaryId,
        {'status': 'inactive'},
      );

      if (_currentOrganizationId != null) {
        add(PartnerLoadBeneficiaries(organizationId: _currentOrganizationId!));
      }
    } catch (e) {
      emit(PartnerError(e.toString()));
    }
  }
}