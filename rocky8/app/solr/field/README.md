## 2. Solr

### 2.1 Add-field-type

```
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field-type": {
    "name": "keyword_analysis",
    "class": "solr.TextField",
    "positionIncrementGap": "100",
    "indexAnalyzer": {
      "tokenizer": {
        "class": "solr.KeywordTokenizerFactory"
      },
      "filters": [
        {
          "class": "solr.LowerCaseFilterFactory"
        },
        {
          "class": "solr.EdgeNGramFilterFactory",
          "maxGramSize": "32",
          "minGramSize": "2"
        }
      ]
    },
    "queryAnalyzer": {
      "tokenizer": {
        "class": "solr.KeywordTokenizerFactory"
      },
      "filters": [
        {
          "class": "solr.LowerCaseFilterFactory"
        }
      ]
    }
  }
}' http://localhost:8983/solr/syslog/schema
```
<hr/>
### 2.2 Replace-field

```
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "replace-field":{
     "name":"logMessage",
     "type":"keyword_analysis",
     "multiValued":false,
     "indexed":true,
     "required":false,
     "stored":true}
}' http://localhost:8983/solr/syslog/schema
```

<hr/>

```
{
  "replace-field-type": {
    "name": "msg_analysis",
    "class": "solr.TextField",
    "positionIncrementGap": "100",
    "indexAnalyzer": {
      "charFilters": [
          {
            "class": "solr.PatternReplaceCharFilterFactory",
            "pattern": "\"",
            "replacement": ""
          },
          {
            "class": "solr.PatternReplaceCharFilterFactory",
            "pattern": "'",
            "replacement": ""
          },
          {
            "class": "solr.PatternReplaceCharFilterFactory",
            "pattern": "msg=audit\\([^)]+\\):",
            "replacement": ""
          },
          {
            "class": "solr.PatternReplaceCharFilterFactory",
            "pattern": "msg=",
            "replacement": ""
          }
      ],
      "tokenizer": {
        "class": "solr.StandardTokenizerFactory"
      },
      "filters": [
        {
          "class": "solr.LowerCaseFilterFactory"
        },
        {
          "class": "solr.EdgeNGramFilterFactory",
          "maxGramSize": "20",
          "minGramSize": "2"
        },
        {
          "class": "solr.StopFilterFactory",
          "ignoreCase": "true",
          "words": "stopwords.txt"
        },
        {
          "class": "solr.SynonymGraphFilterFactory",
          "synonyms": "synonyms.txt",
          "ignoreCase": "true",
          "expand": "true"
        }
      ]
    },
    "queryAnalyzer": {
      "tokenizer": {
        "class": "solr.KeywordTokenizerFactory"
      },
      "filters": [
        {
          "class": "solr.LowerCaseFilterFactory"
        },
        {
          "class": "solr.SynonymGraphFilterFactory",
          "synonyms": "synonyms.txt",
          "ignoreCase": "true",
          "expand": "true"
        }
      ]
    }
  }
}
```

<hr/>

```
curl -X POST -H "Content-type: application/json" --data-binary @schema_syslog_msg.json http://localhost:8983/solr/syslog/schema
```

<hr/>

```
d
```
