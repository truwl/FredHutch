#!/usr/bin/env nextflow

ref_fasta_f = file(params.ref_fasta)
query_ch = Channel.fromPath(file(params.sample_sheet).readLines())

process make_diamond_db {

  publishDir "$params.outdir/"

  container "quay.io/fhcrc-microbiome/docker-diamond@sha256:0f06003c4190e5a1bf73d806146c1b0a3b0d3276d718a50e920670cf1bb395ed"
  cpus 1
  memory "2 GB"

  input:
  file fasta from ref_fasta_f

  output:
  file "${fasta.simpleName}.dmnd" into dmnd

  """
  diamond makedb --in $fasta --db ${fasta.simpleName}.dmnd
  """
}

process align_diamond {

  publishDir "$params.outdir/"

  container "quay.io/fhcrc-microbiome/docker-diamond@sha256:0f06003c4190e5a1bf73d806146c1b0a3b0d3276d718a50e920670cf1bb395ed"
  cpus 4
  memory "2 GB"

  input:
  file ref from dmnd
  each file(query) from query_ch

  output:
  file "${query}.${ref}.aln.gz" into aln_ch

  """
  set -e;

  diamond \
      blastp \
      --db ${ref} \
      --query ${query} \
      --out ${query}.${ref}.aln \
      --outfmt 6 \
      --id 50 \
      --top 0 \
      --query-cover 50 \
      --subject-cover 50 \
      --threads 4;

  gzip ${query}.${ref}.aln
  """  
}

process make_tarball {

  publishDir "$params.outdir/"

  container "quay.io/fhcrc-microbiome/docker-diamond@sha256:0f06003c4190e5a1bf73d806146c1b0a3b0d3276d718a50e920670cf1bb395ed"
  cpus 4
  memory "2 GB"

  input:
  file all_aln from aln_ch.collect()

  output:
  file "all_alignments.tar"

  """
  tar cvf all_alignments.tar *aln.gz
  """

}