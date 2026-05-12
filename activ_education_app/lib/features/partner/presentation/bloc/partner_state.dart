part of 'partner_bloc.dart';

abstract class PartnerState extends Equatable {
  const PartnerState();

  @override
  List<Object?> get props => [];
}

class PartnerInitial extends PartnerState {}

class PartnerLoading extends PartnerState {}

class PartnerOrganizationLoaded extends PartnerState {
  final Organization organization;
  final OrganizationWithStats? stats;

  const PartnerOrganizationLoaded({
    required this.organization,
    this.stats,
  });

  @override
  List<Object?> get props => [organization, stats];
}

class PartnerBeneficiariesLoaded extends PartnerState {
  final List<Beneficiary> beneficiaries;
  final int total;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const PartnerBeneficiariesLoaded({
    required this.beneficiaries,
    required this.total,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [beneficiaries, total, page, hasMore, isLoadingMore];

  PartnerBeneficiariesLoaded copyWith({
    List<Beneficiary>? beneficiaries,
    int? total,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PartnerBeneficiariesLoaded(
      beneficiaries: beneficiaries ?? this.beneficiaries,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class PartnerBeneficiaryCreated extends PartnerState {
  final Beneficiary beneficiary;

  const PartnerBeneficiaryCreated(this.beneficiary);

  @override
  List<Object?> get props => [beneficiary];
}

class PartnerOrganizationCreated extends PartnerState {
  final Organization organization;

  const PartnerOrganizationCreated(this.organization);

  @override
  List<Object?> get props => [organization];
}

class PartnerError extends PartnerState {
  final String message;

  const PartnerError(this.message);

  @override
  List<Object?> get props => [message];
}