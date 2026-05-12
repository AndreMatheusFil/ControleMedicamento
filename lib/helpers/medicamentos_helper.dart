import 'package:string_similarity/string_similarity.dart';

class MedicamentosHelper {
  static const List<String> medicamentos = [
    "dipirona",
    "paracetamol",
    "ibuprofeno",
    "amoxicilina",
    "azitromicina",
    "omeprazol",
    "losartana",
    "metformina",
    "nimesulida",
    "prednisona",
    "clonazepam",
    "rivotril",
    "dorflex",
    "loratadina",
    "cetirizina",
    "sinvastatina",
    "atorvastatina",
    "enalapril",
    "captopril",
    "atenolol",
    "propranolol",
    "furosemida",
    "hidroclorotiazida",
    "fluoxetina",
    "sertralina",
    "escitalopram",
    "diazepam",
    "alprazolam",
    "pantoprazol",
    "domperidona",
    "ondansetrona",
    "buscopan",
    "bromoprida",
    "dexclorfeniramina",
    "ambroxol",
    "salbutamol",
    "budesonida",
    "insulina",
    "glibenclamida",
    "gliclazida",
    "levotiroxina",
    "alendronato",
    "diclofenaco",
    "naproxeno",
    "cetoprofeno",
    "tramadol",
    "morfina",
    "codeina",
    "cefalexina",
    "ciprofloxacino",
    "levofloxacino",
    "metronidazol",
    "fluconazol",
    "aciclovir",
  ];

  static String corrigirNomeMedicamento(String texto) {
    final lower = _normalizar(texto);

    for (final medicamento in medicamentos) {
      if (lower.contains(_normalizar(medicamento))) {
        return _capitalizar(medicamento);
      }
    }

    final palavras = lower
        .split(RegExp(r'[\s\n\r,.;:()\-]+'))
        .where((p) => p.length >= 4)
        .toList();

    String melhorMedicamento = "Medicamento";
    double melhorNota = 0;

    for (final palavra in palavras) {
      for (final medicamento in medicamentos) {
        final nota = palavra.similarityTo(_normalizar(medicamento));

        if (nota > melhorNota) {
          melhorNota = nota;
          melhorMedicamento = medicamento;
        }
      }
    }

    if (melhorNota >= 0.65) {
      return _capitalizar(melhorMedicamento);
    }

    return "Medicamento";
  }

  static String _normalizar(String valor) {
    return valor
        .toLowerCase()
        .replaceAll("á", "a")
        .replaceAll("à", "a")
        .replaceAll("ã", "a")
        .replaceAll("â", "a")
        .replaceAll("é", "e")
        .replaceAll("ê", "e")
        .replaceAll("í", "i")
        .replaceAll("ó", "o")
        .replaceAll("ô", "o")
        .replaceAll("õ", "o")
        .replaceAll("ú", "u")
        .replaceAll("ç", "c");
  }

  static String _capitalizar(String valor) {
    if (valor.isEmpty) return valor;
    return valor[0].toUpperCase() + valor.substring(1);
  }
}