use ExtUtils::MakeMaker;
WriteMakefile(
  AUTHOR => 'attila <attila@stalphonsos.com>',
  ABSTRACT => 'lazy plain-text markup system',
  NAME => 'remark',
  VERSION_FROM => 'remark',
  PREREQ_PM => {
    'IO::File' => 0,
  },
  EXE_FILES => [ 'remark' ],
  PM => {
    'Chapter.pm' => '$(INST_LIBDIR)/Remark/Chapter.pm',
    'Context.pm' => '$(INST_LIBDIR)/Remark/Context.pm',
    'Doc.pm' => '$(INST_LIBDIR)/Remark/Doc.pm',
    'Par.pm' => '$(INST_LIBDIR)/Remark/Par.pm',
    'Sect.pm' => '$(INST_LIBDIR)/Remark/Sect.pm',
    'Utils.pm' => '$(INST_LIBDIR)/Remark/Utils.pm',
    'template.txt' => '$(INST_LIBDIR)/Remark/template.txt',
  }
);
