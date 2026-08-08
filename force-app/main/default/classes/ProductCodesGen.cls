public with sharing class ProductCodesGen {
    public static final String EAN_DO_PREFIX = '84355841';
    public static final String MAX_LEN = 'MAX_Len_Excedido';
    public static final String CODE_IN_USE = 'El código de producto {0} ya está en uso';
    public static final String PROD_BASE_RT_NAME = 'Producto';
    public static final Integer EAN_COUNT_LEN = 4;

    private Set<String> brandsAutoEan;
    private Integer latestEANAssigned;
    private Map<String, Integer> prefixToLastIndex;
    private Set<String> usedCodesInDb;
    private Set<String> reservedCodesInTxn;

    public ProductCodesGen() {
        init(new List<Product2>());
    }

    public ProductCodesGen(List<Product2> scope) {
        init(scope);
    }

    private void init(List<Product2> scope) {brandsAutoEan = new Set<String>(); latestEANAssigned = 0; prefixToLastIndex = new Map<String, Integer>(); usedCodesInDb = new Set<String>(); reservedCodesInTxn = new Set<String>(); loadBrandsAutoEan();
        loadExistingProductCodes(scope); loadLatestEAN();
    }

    public void assignMissingCodes(List<Product2> products) {if (products == null || products.isEmpty()) {return;}

        for (Product2 p : products) {if (String.isBlank(p.ProductCode)) {p.ProductCode = genCodigoDO(p);}

            if (!String.isBlank(p.ProductCode) && isDuplicateAgainstCurrentTxn(p.ProductCode)) {p.addError(String.format(CODE_IN_USE, new List<String>{ p.ProductCode }));continue;}

            if (String.isBlank(p.Codigo_EAN__c) && appliesAutoEAN(p)) {
                p.Codigo_EAN__c = genEAN13();
            }

            if (String.isBlank(p.Codigo_DUN_14__c) && !String.isBlank(p.Codigo_EAN__c)) {
                p.Codigo_DUN_14__c = genDUN14(p.Codigo_EAN__c);
            }
        }
    }

    public Boolean appliesAutoEAN(Product2 p) {if (p == null || String.isBlank(p.Marca__c)) {return false;}String brandToken = getBrandToken(p.Marca__c); return brandsAutoEan.contains(brandToken);}

    public String genCodigoDO(Product2 p) {String prefix = buildPrefix(p);          /* Ej: G501*/ String brandSuffix = getBrandToken(p.Marca__c); // Ej: AR

        Integer nextIndex = prefixToLastIndex.containsKey(prefix)? prefixToLastIndex.get(prefix) + 1: 1; String candidate = buildCode(prefix, nextIndex, brandSuffix);

        while (isPCodeUsed(candidate)) {nextIndex++; candidate = buildCode(prefix, nextIndex, brandSuffix); }
        prefixToLastIndex.put(prefix, nextIndex); reservedCodesInTxn.add(normalize(candidate)); return candidate;
    }

    public String genEAN13() {String newEAN = appendEANCheckSum( EAN_DO_PREFIX + indexToStringLen(latestEANAssigned + 1, EAN_COUNT_LEN)); latestEANAssigned++;return newEAN;} 

    public String genDUN14(String ean13) {String base = '1' + ean13.substring(0, 12); return appendEANCheckSum(base);}

    public Boolean isPCodeUsed(String pc) {String normalized = normalize(pc); return usedCodesInDb.contains(normalized) || reservedCodesInTxn.contains(normalized);}

    private Boolean isDuplicateAgainstCurrentTxn(String pc) {String normalized = normalize(pc);Integer countFound = 0; if (usedCodesInDb.contains(normalized)) {countFound++;} if (reservedCodesInTxn.contains(normalized)) {countFound++;} return countFound > 1;}

    private void loadBrandsAutoEan() {
        for (Marcas_DO__mdt m : [
            SELECT Codigo_de_Marca__c
            FROM Marcas_DO__mdt
        ]) {
            if (!String.isBlank(m.Codigo_de_Marca__c)) {
                brandsAutoEan.add(m.Codigo_de_Marca__c.trim().toUpperCase());
            }
        }
    }

    private void loadExistingProductCodes(List<Product2> scope) {
        Set<String> prefixesNeeded = new Set<String>();

        if (scope != null) {
            for (Product2 p : scope) {
                if (canBuildPrefix(p)) {
                    prefixesNeeded.add(buildPrefix(p));
                }
            }
        }

        for (Product2 existing : [
            SELECT Id, ProductCode
            FROM Product2
            WHERE RecordType.DeveloperName = :PROD_BASE_RT_NAME
              AND ProductCode != null
        ]) {
            String code = normalize(existing.ProductCode);
            usedCodesInDb.add(code);

            for (String prefix : prefixesNeeded) {
                Integer idx = extractIndexForPrefix(code, prefix);
                if (idx == null) {
                    continue;
                }

                if (!prefixToLastIndex.containsKey(prefix) || idx > prefixToLastIndex.get(prefix)) {
                    prefixToLastIndex.put(prefix, idx);
                }
            }
        }
    }

    private void loadLatestEAN() {
        List<Product2> latestEAN = [
            SELECT Codigo_EAN__c
            FROM Product2
            WHERE RecordType.DeveloperName = :PROD_BASE_RT_NAME
              AND Codigo_EAN__c LIKE :EAN_DO_PREFIX + '%'
            ORDER BY Codigo_EAN__c DESC
            LIMIT 1
        ];

        if (!latestEAN.isEmpty() && !String.isBlank(latestEAN[0].Codigo_EAN__c)) {
            latestEANAssigned = getEANCount(latestEAN[0].Codigo_EAN__c, EAN_COUNT_LEN);
        } else {
            latestEANAssigned = 0;
        }
    }

    private String buildPrefix(Product2 p) {
        if (!canBuildPrefix(p)) {
            throw new IllegalArgumentException(
                'No se puede generar el ProductCode. Family, Subfamilia__c y Clase__c son obligatorios y deben tener un valor.'
            );
        }

        String familyToken = getTokenBeforeDash(p.Family).toUpperCase();
        String subfamiliaToken = getTokenBeforeDash(p.Subfamilia__c).toUpperCase();
        String claseToken = getTokenBeforeDash(p.Clase__c).toUpperCase();

        return familyToken + subfamiliaToken + claseToken;
    }

    private Boolean canBuildPrefix(Product2 p) {
        return p != null
            && !String.isBlank(getTokenBeforeDashSafe(p.Family))
            && !String.isBlank(getTokenBeforeDashSafe(p.Subfamilia__c))
            && !String.isBlank(getTokenBeforeDashSafe(p.Clase__c));
    }

    private String buildCode(String prefix, Integer indexValue, String brandSuffix) {
        return prefix + indexToStringLen(indexValue, 3) + brandSuffix;
    }

    private Integer extractIndexForPrefix(String fullCode, String prefix) {
        if (String.isBlank(fullCode) || String.isBlank(prefix)) {
            return null;
        }

        String normalizedCode = normalize(fullCode);
        String normalizedPrefix = normalize(prefix);

        if (!normalizedCode.startsWith(normalizedPrefix)) {
            return null;
        }

        Integer startPos = normalizedPrefix.length();
        Integer endPos = startPos + 3;

        if (normalizedCode.length() < endPos) {
            return null;
        }

        String idxText = normalizedCode.substring(startPos, endPos);
        if (!isNumeric(idxText)) {
            return null;
        }

        return Integer.valueOf(idxText);
    }

    private String getBrandToken(String marca) {
        String token = getTokenBeforeDash(marca).toUpperCase();

        if (String.isBlank(token)) {
            throw new IllegalArgumentException('Marca__c no tiene un formato válido.');
        }

        return token;
    }

    private String getTokenBeforeDash(String value) {
        String result = getTokenBeforeDashSafe(value);

        if (String.isBlank(result)) {
            throw new IllegalArgumentException('Valor inválido para nomenclatura: ' + value);
        }

        return result;
    }

    private String getTokenBeforeDashSafe(String value) {
        if (String.isBlank(value)) {
            return null;
        }

        String cleaned = value.trim();
        Integer dashPos = cleaned.indexOf('-');

        if (dashPos == -1) {
            return cleaned;
        }

        return cleaned.substring(0, dashPos).trim();
    }

    private Boolean isNumeric(String value) {
        if (String.isBlank(value)) {
            return false;
        }

        for (Integer i = 0; i < value.length(); i++) {
            String c = value.substring(i, i + 1);
            if (c < '0' || c > '9') {
                return false;
            }
        }
        return true;
    }

    private String normalize(String value) {
        return String.isBlank(value) ? null : value.trim().toUpperCase();
    }

    private String indexToStringLen(Integer i, Integer maxLength) {
        String result = String.valueOf(i);

        while (result.length() < maxLength) {
            result = '0' + result;
        }

        if (result.length() > maxLength) {
            return MAX_LEN;
        }

        return result;
    }

    private Integer getEANCount(String ean, Integer numDigits) {
        Integer start = 12 - numDigits;
        return Integer.valueOf(ean.substring(start, 12));
    }

    private String appendEANCheckSum(String preEAN) {
        Integer sum = 0;
        Integer weight = 3;

        if (preEAN.length() == 12) {
            weight = 1;
        }

        for (Integer i = 0; i < preEAN.length(); i++) {
            sum += Integer.valueOf(preEAN.substring(i, i + 1)) * weight;
            weight = Math.mod(weight + 2, 4);
        }

        Integer rest = Math.mod(sum, 10) == 0 ? 10 : Math.mod(sum, 10);
        return preEAN + String.valueOf(10 - rest);
    }
}