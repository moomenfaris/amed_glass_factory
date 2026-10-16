class CompanyCustomer {
  final int codeCom;
  final String name;

  const CompanyCustomer({required this.codeCom, required this.name});

  factory CompanyCustomer.fromApi(Map<String, dynamic> j) {
    final code = j['code_com'];
    return CompanyCustomer(
      codeCom: code is num
          ? code.toInt()
          : int.tryParse(code?.toString() ?? '') ?? 0,
      name: (j['name']?.toString() ?? '').trim(),
    );
  }
}
