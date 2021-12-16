process MAKE_PNG {
    tag "png"

    label 'process_medium'

    input:
    path plotterfile
    val ont_cols

    output:
    path "*.png"   , emit: png

    script:
    """
    donor/make_png.R \\
        ${plotterfile} \\
        ${ont_cols}
    """
}
