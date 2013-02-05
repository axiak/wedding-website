from sqlalchemy.sql import compiler
import sqlparse
from sqlparse.filters import TokenFilter
from sqlparse import tokens as T
from termcolor import colored
from sqlparse import engine, filters, formatter


__all__ = [
    'compile_query',
    'pprint_query',
]

def compile_query(statement, bind=None):
    """
    For debug purposes only!
    """
    import sqlalchemy.orm
    if isinstance(statement, sqlalchemy.orm.Query):
        if bind is None:
            bind = statement.session.get_bind(
                    statement._mapper_zero_or_none()
            )
        statement = statement.statement
    elif bind is None:
        bind = statement.bind

    dialect = bind.dialect
    compiler = statement._compiler(dialect)
    class LiteralCompiler(compiler.__class__):
        def visit_bindparam(
                self, bindparam, within_columns_clause=False,
                literal_binds=False, **kwargs
        ):
            return super(LiteralCompiler, self).render_literal_bindparam(
                    bindparam, within_columns_clause=within_columns_clause,
                    literal_binds=literal_binds, **kwargs
            )

    compiler = LiteralCompiler(dialect, statement)
    return compiler.process(statement)

def pprint_query(query, term_colors=True, outer_indent=4):
    options = {
        'reindent': True,
        'keyword_case': 'upper',
        }

    if not isinstance(query, basestring):
        query = compile_query(query)
    if not term_colors:
        lines = sqlparse.format(query, **options).split('\n')
        print '\n'.join(' ' * outer_indent + line for line in lines)
        return
    stack = engine.FilterStack()
    options = formatter.validate_options(options)
    stack = formatter.build_filter_stack(stack, options)
    stack.postprocess.append(_ColorFilter())
    result = ''.join(map(str, stack.run(query)))
    print '\n'.join(' ' * outer_indent + line for line in result.split('\n'))

def C(*args, **kwargs):
    return args, kwargs

class _ColorFilter(TokenFilter):
    _colors = {
        T.Keyword: C('blue', attrs=['bold']),
        T.DML: C('blue', attrs=['bold']),
        T.DDL: C('blue', attrs=['bold']),
        T.Command: C('blue', attrs=['bold']),
        T.String: C('green'),
        T.Name: C('white'),
        }

    def process(self, stack, stmt):
        result = []
        for token in stmt.tokens:
            if token.ttype not in self._colors:
                result.append(token)
            else:
                args, kwargs = self._colors[token.ttype]
                token.value = colored(token.value, *args, **kwargs).strip()
                result.append(token)
        stmt.tokens = result
        return stmt



def log_queries(app):
    if not (app.debug and app.config.get('LOG_SQL', True)):
        return
    import logging
    from logging import StreamHandler
    class QueryHandler(StreamHandler):
        last_queries = {}
        def emit(self, record):
            if record.args and record.thread in self.last_queries:
                params = list(record.args[0].params)
                for key, value in enumerate(params):
                    if isinstance(value, bool):
                        params[key] = {True: 1, False: 0}[value]
                    elif isinstance(value, (float, int)):
                        params[key] = value
                    else:
                        params[key] = "'{}'".format(value)
                try:
                    sql = self.last_queries[record.thread] % tuple(params)
                except:
                    sql = self.last_queries[record.thread]
                print '\nSQL Query\n{}'.format('=' * 45)
                pprint_query(sql)
                print '\n'
                del self.last_queries[record.thread]
            else:
                self.last_queries[record.thread] = record.msg
            #StreamHandler.emit(self, record)

    sqla_logger = logging.getLogger('sqlalchemy.engine')
    sqla_logger.setLevel(logging.INFO)
    for handler in sqla_logger.handlers:
        sqla_logger.removeHandler(handler)
    sqla_logger.addHandler(QueryHandler())

